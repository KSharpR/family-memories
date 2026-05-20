import type { MemoryItem } from "../../domain/memory";

interface MemoryCardProps {
  memory: MemoryItem;
  onEdit(memory: MemoryItem): void;
  onDelete(id: string): void;
}

export function MemoryCard({ memory, onEdit, onDelete }: MemoryCardProps) {
  const story = memory.story.length > 0 ? memory.story : "这段回忆还没有文字。";

  return (
    <article className="memory-card">
      <img
        className={`memory-card-photo${memory.filter === "sepia" ? " photo-filter-sepia" : ""}`}
        src={memory.photoDataUrl}
        alt={story}
      />
      <div className="memory-card-body">
        <p className="memory-card-date">{memory.date ?? "未注明日期"}</p>
        <p className="memory-card-story">{story}</p>
        {memory.people.length > 0 ? (
          <div className="memory-card-people" aria-label="照片中的人物">
            {memory.people.map((person) => (
              <span className="person-tag" key={person}>
                {person}
              </span>
            ))}
          </div>
        ) : null}
        <div className="memory-card-actions">
          <button type="button" className="button" onClick={() => onEdit(memory)}>
            编辑
          </button>
          <button type="button" className="button button-danger" onClick={() => onDelete(memory.id)}>
            删除
          </button>
        </div>
      </div>
    </article>
  );
}
