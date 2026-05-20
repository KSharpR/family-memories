import { useMemo, useRef, useState, type ChangeEvent } from "react";
import type { MemoryItem, NewMemoryInput, UpdateMemoryInput } from "../domain/memory";
import { AlbumView } from "../features/album/AlbumView";
import { FamilyTreeView } from "../features/family-tree/FamilyTreeView";
import { MemoryEditor } from "../features/memories/MemoryEditor";
import { TimelineView } from "../features/memories/TimelineView";
import { readFileAsDataUrl, validateImageFile } from "../features/memories/fileValidation";
import { SlideshowView } from "../features/slideshow/SlideshowView";
import { createLocalMemoryRepository } from "../storage/localMemoryRepository";
import { AppShell } from "./AppShell";
import type { ViewMode } from "./appState";
import { useAlbumController } from "./useAlbumController";
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
  const [activeView, setActiveView] = useState<ViewMode>("timeline");
  const [editor, setEditor] = useState<EditorState | null>(null);
  const [queuedPhotos, setQueuedPhotos] = useState<QueuedPhoto[]>([]);
  const photoInputRef = useRef<HTMLInputElement>(null);
  const uploadIdRef = useRef(0);

  async function handleExport() {
    try {
      await controller.exportAlbum();
      showToast("相册已准备导出，文件保存将在后续任务接入");
    } catch (error) {
      showToast(error instanceof Error ? error.message : "相册导出失败");
    }
  }

  function handleImport() {
    showToast("导入文件选择将在后续任务接入");
  }

  async function readPhotos(files: FileList | File[]): Promise<string[]> {
    const photos: string[] = [];

    for (const file of Array.from(files)) {
      const validation = validateImageFile(file);
      if (!validation.ok) {
        showToast(validation.message);
        continue;
      }

      try {
        photos.push(await readFileAsDataUrl(file));
      } catch (error) {
        showToast(error instanceof Error ? error.message : "图片读取失败");
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
    showToast("已保存回忆");
  }

  async function handleSaveEdit(id: string, input: UpdateMemoryInput) {
    await controller.updateMemory(id, input);
    showToast("已更新回忆");
  }

  async function handleDelete(id: string) {
    try {
      await controller.deleteMemory(id);
      showToast("已删除回忆");
    } catch (error) {
      showToast(error instanceof Error ? error.message : "删除回忆失败");
    }
  }

  function renderContent() {
    if (controller.isLoading) {
      return (
        <section className="panel-state" aria-live="polite">
          正在整理相册...
        </section>
      );
    }

    if (controller.error) {
      return (
        <section className="panel-state panel-state-error" role="alert">
          {controller.error}
          <button type="button" className="button" onClick={() => void controller.reload()}>
            重试
          </button>
        </section>
      );
    }

    if (activeView === "album") {
      return <AlbumView memories={controller.memories} />;
    }

    if (activeView === "family-tree") {
      return <FamilyTreeView memories={controller.memories} />;
    }

    if (activeView === "slideshow") {
      return <SlideshowView memories={controller.memories} />;
    }

    return (
      <TimelineView
        memories={controller.memories}
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
      title={controller.album.title}
      activeView={activeView}
      memoryCount={controller.memories.length}
      onChangeView={setActiveView}
      onAddPhotos={() => photoInputRef.current?.click()}
      onImport={handleImport}
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

      {renderContent()}

      {editor ? (
        <MemoryEditor
          key={editor.type === "new" ? editor.uploadId : editor.memory.id}
          mode={editor}
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
