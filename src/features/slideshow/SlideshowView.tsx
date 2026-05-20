import { useEffect, useMemo, useState } from "react";
import { sortMemories } from "../../app/appState";
import { translations, type AppCopy } from "../../app/i18n";
import type { MemoryItem } from "../../domain/memory";

interface SlideshowViewProps {
  memories: MemoryItem[];
  copy?: AppCopy["slideshow"];
}

export function SlideshowView({
  memories,
  copy = translations.zh.slideshow
}: SlideshowViewProps) {
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
        <h2>{copy.emptyTitle}</h2>
        <p>{copy.emptyCopy}</p>
      </section>
    );
  }

  const story = currentMemory.story.length > 0 ? currentMemory.story : copy.fallbackStory;
  const people = currentMemory.people.join("、");

  return (
    <section className="slideshow-view" aria-label={copy.ariaLabel}>
      <figure className="slideshow-stage">
        <img
          className={`slideshow-photo${currentMemory.filter === "sepia" ? " photo-filter-sepia" : ""}`}
          src={currentMemory.photoDataUrl}
          alt={story}
        />
      </figure>
      <div className="slideshow-caption" aria-label={copy.captionLabel}>
        <div className="slideshow-meta">
          <p className="slideshow-date">{currentMemory.date ?? copy.fallbackDate}</p>
          <p className="slideshow-count" aria-label={copy.pageNumberLabel}>
            {currentSlideIndex + 1} / {sortedMemories.length}
          </p>
        </div>
        <p className="slideshow-story">{story}</p>
        {people.length > 0 ? (
          <p className="slideshow-people" aria-label={copy.peopleLabel}>
            {people}
          </p>
        ) : null}
      </div>

      <div className="slideshow-controls" aria-label={copy.controlsLabel}>
        <button
          type="button"
          className="button"
          disabled={currentSlideIndex === 0}
          onClick={() => setCurrentIndex((index) => Math.max(index - 1, 0))}
        >
          {copy.previous}
        </button>
        <button
          type="button"
          className="button button-primary"
          disabled={!canPlay}
          onClick={() => setIsPlaying((playing) => !playing)}
        >
          {isActivelyPlaying ? copy.pause : copy.play}
        </button>
        <button
          type="button"
          className="button"
          disabled={currentSlideIndex === lastIndex}
          onClick={() => setCurrentIndex((index) => Math.min(index + 1, lastIndex))}
        >
          {copy.next}
        </button>
      </div>
    </section>
  );
}
