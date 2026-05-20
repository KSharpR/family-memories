import { useEffect, useMemo, useState } from "react";
import { sortMemories } from "../../app/appState";
import { translations, type AppCopy } from "../../app/i18n";
import type { MemoryItem } from "../../domain/memory";
import { AlbumPage } from "./AlbumPage";

interface AlbumViewProps {
  memories: MemoryItem[];
  copy?: AppCopy["album"];
}

export function AlbumView({ memories, copy = translations.zh.album }: AlbumViewProps) {
  const sortedMemories = useMemo(() => sortMemories(memories), [memories]);
  const [pageIndex, setPageIndex] = useState(0);
  const lastPageIndex = sortedMemories.length - 1;
  const currentPageIndex = Math.min(pageIndex, Math.max(lastPageIndex, 0));
  const currentMemory = sortedMemories[currentPageIndex];

  useEffect(() => {
    if (pageIndex > lastPageIndex) {
      setPageIndex(Math.max(lastPageIndex, 0));
    }
  }, [lastPageIndex, pageIndex]);

  if (sortedMemories.length === 0) {
    return (
      <section className="empty-state album-empty">
        <h2>{copy.emptyTitle}</h2>
        <p>{copy.emptyCopy}</p>
      </section>
    );
  }

  return (
    <section className="album-view" aria-label={copy.ariaLabel}>
      <AlbumPage
        memory={currentMemory}
        index={currentPageIndex}
        total={sortedMemories.length}
        copy={copy}
      />

      <div className="album-controls" aria-label={copy.pageControlsLabel}>
        <button
          type="button"
          className="button"
          disabled={currentPageIndex === 0}
          onClick={() => setPageIndex((index) => Math.max(index - 1, 0))}
        >
          {copy.previous}
        </button>
        <button
          type="button"
          className="button button-primary"
          disabled={currentPageIndex === lastPageIndex}
          onClick={() => setPageIndex((index) => Math.min(index + 1, lastPageIndex))}
        >
          {copy.next}
        </button>
      </div>
    </section>
  );
}
