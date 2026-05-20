import { useEffect, useMemo, useState } from "react";
import { sortMemories } from "../../app/appState";
import type { MemoryItem } from "../../domain/memory";

interface SlideshowViewProps {
  memories: MemoryItem[];
}

export function SlideshowView({ memories }: SlideshowViewProps) {
  const sortedMemories = useMemo(() => sortMemories(memories), [memories]);
  const [currentIndex, setCurrentIndex] = useState(0);
  const [isPlaying, setIsPlaying] = useState(false);
  const lastIndex = sortedMemories.length - 1;
  const safeLastIndex = Math.max(lastIndex, 0);
  const currentSlideIndex = Math.min(currentIndex, safeLastIndex);
  const currentMemory = sortedMemories[currentSlideIndex];
  const canPlay = sortedMemories.length > 1;
  const isActivelyPlaying = isPlaying && canPlay;

  useEffect(() => {
    if (currentIndex > lastIndex) {
      setCurrentIndex(safeLastIndex);
    }
  }, [currentIndex, lastIndex, safeLastIndex]);

  useEffect(() => {
    if (!isActivelyPlaying) {
      return undefined;
    }

    const intervalId = window.setInterval(() => {
      setCurrentIndex((index) => (index >= lastIndex ? 0 : index + 1));
    }, 4200);

    return () => window.clearInterval(intervalId);
  }, [isActivelyPlaying, lastIndex]);

  if (sortedMemories.length === 0) {
    return (
      <section className="empty-state slideshow-empty">
        <h2>还没有可播放的照片</h2>
        <p>回到时间线添加照片后，可以在这里播放回忆。</p>
      </section>
    );
  }

  const story = currentMemory.story.length > 0 ? currentMemory.story : "照片记录了这段时光。";
  const people = currentMemory.people.join("、");

  return (
    <section className="slideshow-view" aria-label="幻灯片播放">
      <figure className="slideshow-stage">
        <img
          className={`slideshow-photo${currentMemory.filter === "sepia" ? " photo-filter-sepia" : ""}`}
          src={currentMemory.photoDataUrl}
          alt={story}
        />
      </figure>
      <div className="slideshow-caption" aria-label="幻灯片说明">
        <div className="slideshow-meta">
          <p className="slideshow-date">{currentMemory.date ?? "未标注日期"}</p>
          <p className="slideshow-count" aria-label="幻灯片页码">
            {currentSlideIndex + 1} / {sortedMemories.length}
          </p>
        </div>
        <p className="slideshow-story">{story}</p>
        {people.length > 0 ? (
          <p className="slideshow-people" aria-label="照片中的人物">
            {people}
          </p>
        ) : null}
      </div>

      <div className="slideshow-controls" aria-label="幻灯片控制">
        <button
          type="button"
          className="button"
          disabled={currentSlideIndex === 0}
          onClick={() => setCurrentIndex((index) => Math.max(index - 1, 0))}
        >
          上一张
        </button>
        <button
          type="button"
          className="button button-primary"
          disabled={!canPlay}
          onClick={() => setIsPlaying((playing) => !playing)}
        >
          {isActivelyPlaying ? "暂停" : "播放"}
        </button>
        <button
          type="button"
          className="button"
          disabled={currentSlideIndex === lastIndex}
          onClick={() => setCurrentIndex((index) => Math.min(index + 1, lastIndex))}
        >
          下一张
        </button>
      </div>
    </section>
  );
}
