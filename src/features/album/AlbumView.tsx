import { useEffect, useMemo, useState } from "react";
import { sortMemories } from "../../app/appState";
import type { MemoryItem } from "../../domain/memory";
import { AlbumPage } from "./AlbumPage";

interface AlbumViewProps {
  memories: MemoryItem[];
}

export function AlbumView({ memories }: AlbumViewProps) {
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
        <h2>相册还没有内容</h2>
        <p>回到时间线添加照片后，这里会生成翻页相册。</p>
      </section>
    );
  }

  return (
    <section className="album-view" aria-label="翻页相册">
      <AlbumPage memory={currentMemory} index={currentPageIndex} total={sortedMemories.length} />

      <div className="album-controls" aria-label="相册翻页">
        <button
          type="button"
          className="button"
          disabled={currentPageIndex === 0}
          onClick={() => setPageIndex((index) => Math.max(index - 1, 0))}
        >
          上一页
        </button>
        <button
          type="button"
          className="button button-primary"
          disabled={currentPageIndex === lastPageIndex}
          onClick={() => setPageIndex((index) => Math.min(index + 1, lastPageIndex))}
        >
          下一页
        </button>
      </div>
    </section>
  );
}
