import type { AppCopy } from "../../app/i18n";
import type { MemoryItem } from "../../domain/memory";

interface AlbumPageProps {
  memory: MemoryItem;
  index: number;
  total: number;
  copy: AppCopy["album"];
}

export function AlbumPage({ memory, index, total, copy }: AlbumPageProps) {
  const story = memory.story.length > 0 ? memory.story : copy.fallbackStory;
  const people = memory.people.join("、");

  return (
    <article className="album-page">
      <figure className="album-page-photo-frame">
        <img
          className={`album-page-photo${memory.filter === "sepia" ? " photo-filter-sepia" : ""}`}
          src={memory.photoDataUrl}
          alt={story}
        />
      </figure>

      <div className="album-page-body">
        <div className="album-page-meta">
          <p className="album-page-date">{memory.date ?? copy.fallbackDate}</p>
          <p className="album-page-count" aria-label={copy.pageNumberLabel}>
            {index + 1} / {total}
          </p>
        </div>
        <p className="album-page-story">{story}</p>
        {people.length > 0 ? (
          <p className="album-page-people" aria-label={copy.peopleLabel}>
            {people}
          </p>
        ) : null}
      </div>
    </article>
  );
}
