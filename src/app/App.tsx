import { useMemo, useRef, useState, type ChangeEvent } from "react";
import type { MemoryItem, NewMemoryInput, UpdateMemoryInput } from "../domain/memory";
import { AlbumView } from "../features/album/AlbumView";
import { FamilyTreeView } from "../features/family-tree/FamilyTreeView";
import { MemoryEditor } from "../features/memories/MemoryEditor";
import { TimelineView } from "../features/memories/TimelineView";
import {
  IMAGE_READ_ERROR_MESSAGE,
  IMAGE_TOO_LARGE_MESSAGE,
  INVALID_IMAGE_TYPE_MESSAGE,
  readFileAsDataUrl,
  validateImageFile
} from "../features/memories/fileValidation";
import { SlideshowView } from "../features/slideshow/SlideshowView";
import { createLocalMemoryRepository } from "../storage/localMemoryRepository";
import { IMPORT_ERROR_MESSAGE } from "../storage/serializers";
import { AppShell } from "./AppShell";
import type { ViewMode } from "./appState";
import {
  readStoredLanguage,
  translations,
  writeStoredLanguage,
  type AppCopy,
  type Language
} from "./i18n";
import { ALBUM_LOAD_ERROR_MESSAGE, useAlbumController } from "./useAlbumController";
import { useToast } from "./useToast";

type EditorState =
  | { type: "new"; uploadId: string; photoDataUrl: string }
  | { type: "edit"; memory: MemoryItem };

interface QueuedPhoto {
  uploadId: string;
  photoDataUrl: string;
}

export function App() {
  const repository = useMemo(() => createLocalMemoryRepository(), []);
  const controller = useAlbumController(repository);
  const { message, showToast } = useToast();
  const [language, setLanguage] = useState<Language>(() => readStoredLanguage());
  const copy = translations[language];
  const [activeView, setActiveView] = useState<ViewMode>("timeline");
  const [editor, setEditor] = useState<EditorState | null>(null);
  const [queuedPhotos, setQueuedPhotos] = useState<QueuedPhoto[]>([]);
  const photoInputRef = useRef<HTMLInputElement>(null);
  const importInputRef = useRef<HTMLInputElement>(null);
  const uploadIdRef = useRef(0);

  async function handleExport() {
    try {
      const serialized = await controller.exportAlbum();
      const blob = new Blob([serialized], { type: "application/json" });
      const url = URL.createObjectURL(blob);
      const anchor = document.createElement("a");
      anchor.href = url;
      anchor.download = `family-memories-${formatDateForFilename(new Date())}.json`;
      anchor.click();
      URL.revokeObjectURL(url);
      showToast(copy.toasts.exportSuccess);
    } catch (error) {
      showToast(
        error instanceof Error ? translateExportError(error.message, copy) : copy.errors.exportFailed
      );
    }
  }

  async function handleImportInputChange(event: ChangeEvent<HTMLInputElement>) {
    const input = event.currentTarget;
    const file = input.files?.[0];

    if (!file) {
      return;
    }

    try {
      const serialized = await readFileAsText(file, copy.errors.importFailed);
      await controller.importAlbum(serialized);
      showToast(copy.toasts.importSuccess);
    } catch (error) {
      showToast(
        error instanceof Error ? translateImportError(error.message, copy) : copy.errors.importFailed
      );
    } finally {
      input.value = "";
    }
  }

  async function readPhotos(files: FileList | File[]): Promise<string[]> {
    const photos: string[] = [];

    for (const file of Array.from(files)) {
      const validation = validateImageFile(file);
      if (!validation.ok) {
        showToast(translateImageError(validation.message, copy));
        continue;
      }

      try {
        photos.push(await readFileAsDataUrl(file));
      } catch (error) {
        showToast(
          error instanceof Error
            ? translateImageError(error.message, copy)
            : copy.errors.readImageFailed
        );
      }
    }

    return photos;
  }

  async function handlePhotoInputChange(event: ChangeEvent<HTMLInputElement>) {
    const input = event.currentTarget;
    const files = input.files;
    const photos = files ? await readPhotos(files) : [];
    input.value = "";
    openNewEditor(photos);
  }

  function openNewEditor(photos: string[]) {
    const nextPhotos = photos.map((photoDataUrl) => ({
      uploadId: `upload-${++uploadIdRef.current}`,
      photoDataUrl
    }));
    const [firstPhoto, ...remainingPhotos] = nextPhotos;

    if (firstPhoto) {
      setQueuedPhotos(remainingPhotos);
      setEditor({ type: "new", ...firstPhoto });
    }
  }

  function closeEditor() {
    if (editor?.type === "new" && queuedPhotos.length > 0) {
      const nextPhoto = queuedPhotos[0];
      const remainingPhotos = queuedPhotos.slice(1);
      setQueuedPhotos(remainingPhotos);
      setEditor({ type: "new", ...nextPhoto });
      return;
    }

    setQueuedPhotos([]);
    setEditor(null);
  }

  async function handleSaveNew(input: NewMemoryInput) {
    await controller.addMemory(input);
    showToast(copy.toasts.saveNew);
  }

  async function handleSaveEdit(id: string, input: UpdateMemoryInput) {
    await controller.updateMemory(id, input);
    showToast(copy.toasts.saveEdit);
  }

  async function handleDelete(id: string) {
    try {
      await controller.deleteMemory(id);
      showToast(copy.toasts.delete);
    } catch (error) {
      showToast(error instanceof Error ? error.message : copy.errors.deleteFailed);
    }
  }

  function handleLanguageChange(nextLanguage: Language) {
    setLanguage(nextLanguage);
    writeStoredLanguage(nextLanguage);
  }

  function renderContent() {
    if (controller.isLoading) {
      return (
        <section className="panel-state" aria-live="polite">
          {copy.states.loading}
        </section>
      );
    }

    if (controller.error) {
      return (
        <section className="panel-state panel-state-error" role="alert">
          {translateControllerError(controller.error, copy)}
          <button type="button" className="button" onClick={() => void controller.reload()}>
            {copy.states.retry}
          </button>
        </section>
      );
    }

    if (activeView === "album") {
      return <AlbumView memories={controller.memories} copy={copy.album} />;
    }

    if (activeView === "family-tree") {
      return <FamilyTreeView memories={controller.memories} copy={copy.familyTree} />;
    }

    if (activeView === "slideshow") {
      return <SlideshowView memories={controller.memories} copy={copy.slideshow} />;
    }

    return (
      <TimelineView
        memories={controller.memories}
        copy={copy}
        onPhotosReady={openNewEditor}
        onUploadError={showToast}
        onEdit={(memory) => setEditor({ type: "edit", memory })}
        onDelete={(id) => {
          void handleDelete(id);
        }}
      />
    );
  }

  return (
    <AppShell
      title={resolveAlbumTitle(controller.album.title, copy.appTitle)}
      activeView={activeView}
      memoryCount={controller.memories.length}
      language={language}
      copy={copy}
      onChangeView={setActiveView}
      onChangeLanguage={handleLanguageChange}
      onAddPhotos={() => photoInputRef.current?.click()}
      onImport={() => importInputRef.current?.click()}
      onExport={() => {
        void handleExport();
      }}
    >
      <input
        ref={photoInputRef}
        className="visually-hidden"
        type="file"
        accept="image/png,image/jpeg,image/webp,image/gif"
        multiple
        onChange={(event) => {
          void handlePhotoInputChange(event);
        }}
      />
      <input
        ref={importInputRef}
        className="visually-hidden"
        type="file"
        accept="application/json,.json"
        onChange={(event) => {
          void handleImportInputChange(event);
        }}
      />

      {renderContent()}

      {editor ? (
        <MemoryEditor
          key={editor.type === "new" ? editor.uploadId : editor.memory.id}
          mode={editor}
          copy={copy.editor}
          saveErrorMessage={copy.errors.saveFailed}
          onSaveNew={handleSaveNew}
          onSaveEdit={handleSaveEdit}
          onCancel={closeEditor}
          onError={showToast}
        />
      ) : null}

      {message ? (
        <div className="toast" role="status" aria-live="polite">
          {message}
        </div>
      ) : null}
    </AppShell>
  );
}

function formatDateForFilename(date: Date): string {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, "0");
  const day = String(date.getDate()).padStart(2, "0");
  return `${year}-${month}-${day}`;
}

function readFileAsText(file: File, fallbackErrorMessage: string): Promise<string> {
  if ("text" in file && typeof file.text === "function") {
    return file.text();
  }

  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.addEventListener("load", () => {
      resolve(String(reader.result ?? ""));
    });
    reader.addEventListener("error", () => {
      reject(reader.error ?? new Error(fallbackErrorMessage));
    });
    reader.readAsText(file);
  });
}

function resolveAlbumTitle(albumTitle: string, defaultTitle: string): string {
  return albumTitle === translations.zh.appTitle ? defaultTitle : albumTitle;
}

function translateImageError(message: string, copy: AppCopy): string {
  if (message === INVALID_IMAGE_TYPE_MESSAGE) {
    return copy.errors.invalidImageType;
  }
  if (message === IMAGE_TOO_LARGE_MESSAGE) {
    return copy.errors.imageTooLarge;
  }
  if (message === IMAGE_READ_ERROR_MESSAGE) {
    return copy.errors.readImageFailed;
  }
  return message;
}

function translateImportError(message: string, copy: AppCopy): string {
  return message === IMPORT_ERROR_MESSAGE ? copy.errors.importFailed : message;
}

function translateExportError(message: string, copy: AppCopy): string {
  return message === IMPORT_ERROR_MESSAGE ? copy.errors.exportFailed : message;
}

function translateControllerError(message: string, copy: AppCopy): string {
  if (message === IMPORT_ERROR_MESSAGE || message === ALBUM_LOAD_ERROR_MESSAGE) {
    return copy.errors.loadFailed;
  }
  return message;
}
