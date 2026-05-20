import { useEffect, useRef, useState, type FormEvent, type KeyboardEvent } from "react";
import { translations, type AppCopy } from "../../app/i18n";
import type { MemoryFilter, MemoryItem, NewMemoryInput, UpdateMemoryInput } from "../../domain/memory";

type EditorMode =
  | { type: "new"; photoDataUrl: string }
  | { type: "edit"; memory: MemoryItem };

interface MemoryEditorProps {
  mode: EditorMode;
  copy?: AppCopy["editor"];
  saveErrorMessage?: string;
  onSaveNew(input: NewMemoryInput): Promise<void>;
  onSaveEdit(id: string, input: UpdateMemoryInput): Promise<void>;
  onCancel(): void;
  onError(message: string): void;
}

export function MemoryEditor({
  mode,
  copy = translations.zh.editor,
  saveErrorMessage = translations.zh.errors.saveFailed,
  onSaveNew,
  onSaveEdit,
  onCancel,
  onError
}: MemoryEditorProps) {
  const memory = mode.type === "edit" ? mode.memory : null;
  const [story, setStory] = useState(memory?.story ?? "");
  const [date, setDate] = useState(memory?.date ?? new Date().toISOString().slice(0, 10));
  const [people, setPeople] = useState(memory?.people.join("\n") ?? "");
  const [filter, setFilter] = useState<MemoryFilter>(memory?.filter ?? "none");
  const [isSaving, setIsSaving] = useState(false);
  const dialogRef = useRef<HTMLElement | null>(null);
  const photoDataUrl = mode.type === "new" ? mode.photoDataUrl : mode.memory.photoDataUrl;

  useEffect(() => {
    dialogRef.current?.focus();
  }, []);

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setIsSaving(true);

    const input = {
      story,
      date: date.length > 0 ? date : null,
      people: splitPeople(people),
      filter
    };

    try {
      if (mode.type === "new") {
        await onSaveNew({
          ...input,
          photoDataUrl
        });
      } else {
        await onSaveEdit(mode.memory.id, input);
      }
      onCancel();
    } catch (error) {
      onError(error instanceof Error ? error.message : saveErrorMessage);
    } finally {
      setIsSaving(false);
    }
  }

  function requestClose() {
    if (!isSaving) {
      onCancel();
    }
  }

  function handleDialogKeyDown(event: KeyboardEvent<HTMLElement>) {
    if (event.key === "Escape") {
      event.preventDefault();
      requestClose();
      return;
    }

    if (event.key === "Tab") {
      trapFocus(event);
    }
  }

  return (
    <div
      className="memory-editor-backdrop"
      role="presentation"
      onMouseDown={(event) => {
        if (event.target === event.currentTarget) {
          requestClose();
        }
      }}
    >
      <section
        ref={dialogRef}
        className="memory-editor"
        role="dialog"
        aria-modal="true"
        aria-labelledby="memory-editor-title"
        tabIndex={-1}
        onKeyDown={handleDialogKeyDown}
      >
        <div className="memory-editor-preview">
          <img className={filter === "sepia" ? "photo-filter-sepia" : ""} src={photoDataUrl} alt="" />
        </div>
        <form className="memory-editor-form" onSubmit={(event) => void handleSubmit(event)}>
          <div className="memory-editor-heading">
            <h2 id="memory-editor-title">{mode.type === "new" ? copy.newTitle : copy.editTitle}</h2>
            <button type="button" className="button" onClick={requestClose} disabled={isSaving}>
              {copy.close}
            </button>
          </div>

          <label className="field-group">
            <span>{copy.story}</span>
            <textarea
              value={story}
              rows={5}
              placeholder={copy.storyPlaceholder}
              onChange={(event) => setStory(event.currentTarget.value)}
            />
          </label>

          <div className="editor-field-grid">
            <label className="field-group">
              <span>{copy.date}</span>
              <input
                type="date"
                value={date}
                onChange={(event) => setDate(event.currentTarget.value)}
              />
            </label>
            <label className="field-group">
              <span>{copy.filter}</span>
              <select
                value={filter}
                onChange={(event) => setFilter(event.currentTarget.value as MemoryFilter)}
              >
                <option value="none">{copy.filterNone}</option>
                <option value="sepia">{copy.filterSepia}</option>
              </select>
            </label>
          </div>

          <label className="field-group">
            <span>{copy.people}</span>
            <textarea
              value={people}
              rows={3}
              placeholder={copy.peoplePlaceholder}
              onChange={(event) => setPeople(event.currentTarget.value)}
            />
          </label>

          <div className="memory-editor-actions">
            <button type="button" className="button" onClick={requestClose} disabled={isSaving}>
              {copy.cancel}
            </button>
            <button type="submit" className="button button-primary" disabled={isSaving}>
              {isSaving ? copy.saving : copy.save}
            </button>
          </div>
        </form>
      </section>
    </div>
  );
}

function trapFocus(event: KeyboardEvent<HTMLElement>) {
  const focusableElements = Array.from(
    event.currentTarget.querySelectorAll<HTMLElement>(
      'button:not([disabled]), input:not([disabled]), select:not([disabled]), textarea:not([disabled]), [href], [tabindex]:not([tabindex="-1"])'
    )
  );

  if (focusableElements.length === 0) {
    event.preventDefault();
    return;
  }

  const firstElement = focusableElements[0];
  const lastElement = focusableElements[focusableElements.length - 1];
  const activeElement = document.activeElement;

  if (activeElement === event.currentTarget || !event.currentTarget.contains(activeElement)) {
    event.preventDefault();
    (event.shiftKey ? lastElement : firstElement).focus();
    return;
  }

  if (event.shiftKey && activeElement === firstElement) {
    event.preventDefault();
    lastElement.focus();
    return;
  }

  if (!event.shiftKey && activeElement === lastElement) {
    event.preventDefault();
    firstElement.focus();
  }
}

function splitPeople(value: string): string[] {
  return value
    .split(/[、,，\n]+/)
    .map((person) => person.trim())
    .filter(Boolean);
}
