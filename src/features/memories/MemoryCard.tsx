import type { AppCopy } from "../../app/i18n";
import type { MemoryItem } from "../../domain/memory";

interface MemoryCardProps {
  memory: MemoryItem;
  copy: AppCopy["memoryCard"];
  onEdit(memory: MemoryItem): void;
  onDelete(id: string): void;
}

export function MemoryCard({ memory, copy, onEdit, onDelete }: MemoryCardProps) {
  const story = memory.story.length > 0 ? memory.story : copy.fallbackStory;

  return (
    <article className="memory-card">
      <img
        className={`memory-card-photo${memory.filter === "sepia" ? " photo-filter-sepia" : ""}`}
        src={memory.photoDataUrl}
        alt={story}
      />
      <div className="memory-card-body">
        <p className="memory-card-date">{memory.date ?? copy.fallbackDate}</p>
        <p className="memory-card-story">{story}</p>
        {memory.people.length > 0 ? (
          <div className="memory-card-people" aria-label={copy.peopleLabel}>
            {memory.people.map((person) => (
              <span className="person-tag" key={person}>
                {person}
              </span>
            ))}
          </div>
        ) : null}
        <div className="memory-card-actions">
          <button type="button" className="button" onClick={() => onEdit(memory)}>
            {copy.edit}
          </button>
          <button type="button" className="button button-danger" onClick={() => onDelete(memory.id)}>
            {copy.delete}
          </button>
        </div>
      </div>
    </article>
  );
}
