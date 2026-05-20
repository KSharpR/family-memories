import { groupMemoriesByMonth } from "../../app/appState";
import type { AppCopy } from "../../app/i18n";
import type { MemoryItem } from "../../domain/memory";
import { MemoryCard } from "./MemoryCard";
import { UploadDropzone } from "./UploadDropzone";

interface TimelineViewProps {
  memories: MemoryItem[];
  copy: AppCopy;
  onPhotosReady(photos: string[]): void;
  onUploadError(message: string): void;
  onEdit(memory: MemoryItem): void;
  onDelete(id: string): void;
}

export function TimelineView({
  memories,
  copy,
  onPhotosReady,
  onUploadError,
  onEdit,
  onDelete
}: TimelineViewProps) {
  const groups = groupMemoriesByMonth(memories);

  return (
    <div className="timeline-view">
      <UploadDropzone
        copy={copy.upload}
        errors={copy.errors}
        actions={copy.actions}
        onPhotosReady={onPhotosReady}
        onError={onUploadError}
      />

      {groups.length === 0 ? (
        <section className="empty-state timeline-empty">
          <h2>{copy.timeline.emptyTitle}</h2>
          <p>{copy.timeline.emptyCopy}</p>
        </section>
      ) : (
        <div className="timeline-months" aria-label={copy.timeline.ariaLabel}>
          {groups.map((group) => (
            <section className="timeline-month-group" key={group.key}>
              <div className="timeline-month-heading">
                <p>{group.year}</p>
                <h2>{copy.timeline.formatMonth(group.year, group.month)}</h2>
              </div>
              <div className="memory-card-grid">
                {group.memories.map((memory) => (
                  <MemoryCard
                    key={memory.id}
                    memory={memory}
                    copy={copy.memoryCard}
                    onEdit={onEdit}
                    onDelete={onDelete}
                  />
                ))}
              </div>
            </section>
          ))}
        </div>
      )}
    </div>
  );
}
