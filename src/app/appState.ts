import type { MemoryItem } from "../domain/memory";

export type ViewMode = "timeline" | "album" | "family-tree" | "slideshow";

export interface MemoryMonthGroup {
  key: string;
  year: string;
  month: string;
  label: string;
  memories: MemoryItem[];
}

export function sortMemories(memories: MemoryItem[]): MemoryItem[] {
  return [...memories].sort((left, right) => {
    const leftHasDate = left.date !== null;
    const rightHasDate = right.date !== null;

    if (leftHasDate !== rightHasDate) {
      return leftHasDate ? -1 : 1;
    }

    return getSortableDate(right).localeCompare(getSortableDate(left));
  });
}

export function groupMemoriesByMonth(memories: MemoryItem[]): MemoryMonthGroup[] {
  const groups = new Map<string, MemoryMonthGroup>();

  for (const memory of sortMemories(memories)) {
    const key = getSortableDate(memory).slice(0, 7);
    const [year, month] = key.split("-");
    const group = groups.get(key) ?? {
      key,
      year,
      month,
      label: `${year}年${month}月`,
      memories: []
    };

    group.memories.push(memory);
    groups.set(key, group);
  }

  return Array.from(groups.values());
}

function getSortableDate(memory: MemoryItem): string {
  return memory.date ?? memory.createdAt.slice(0, 10);
}
