import { groupMemoriesByMonth } from "../../app/appState";
import type { MemoryItem } from "../../domain/memory";
import { MemoryCard } from "./MemoryCard";
import { UploadDropzone } from "./UploadDropzone";

interface TimelineViewProps {
  memories: MemoryItem[];
  onPhotosReady(photos: string[]): void;
  onUploadError(message: string): void;
  onEdit(memory: MemoryItem): void;
  onDelete(id: string): void;
}

export function TimelineView({
  memories,
  onPhotosReady,
  onUploadError,
  onEdit,
  onDelete
}: TimelineViewProps) {
  const groups = groupMemoriesByMonth(memories);

  return (
    <div className="timeline-view">
      <UploadDropzone onPhotosReady={onPhotosReady} onError={onUploadError} />

      {groups.length === 0 ? (
        <section className="empty-state timeline-empty">
          <h2>还没有照片</h2>
          <p>添加第一张照片，开始整理家族回忆。</p>
        </section>
      ) : (
        <div className="timeline-months" aria-label="回忆时间线">
          {groups.map((group) => (
            <section className="timeline-month-group" key={group.key}>
              <div className="timeline-month-heading">
                <p>{group.year}</p>
                <h2>{group.label}</h2>
              </div>
              <div className="memory-card-grid">
                {group.memories.map((memory) => (
                  <MemoryCard
                    key={memory.id}
                    memory={memory}
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
