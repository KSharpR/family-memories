import type { MemoryItem } from "../../domain/memory";

interface AlbumPageProps {
  memory: MemoryItem;
  index: number;
  total: number;
}

export function AlbumPage({ memory, index, total }: AlbumPageProps) {
  const story = memory.story.length > 0 ? memory.story : "照片记录了这段时光。";
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
          <p className="album-page-date">{memory.date ?? "未标注日期"}</p>
          <p className="album-page-count" aria-label="页码">
            {index + 1} / {total}
          </p>
        </div>
        <p className="album-page-story">{story}</p>
        {people.length > 0 ? (
          <p className="album-page-people" aria-label="照片中的人物">
            {people}
          </p>
        ) : null}
      </div>
    </article>
  );
}
