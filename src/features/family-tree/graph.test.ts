import { describe, expect, it } from "vitest";
import type { MemoryItem } from "../../domain/memory";
import { buildPeopleGraph } from "./graph";

const baseMemory: MemoryItem = {
  id: "memory-1",
  photoDataUrl: "data:image/png;base64,YWJj",
  story: "家里的晚饭",
  date: "2026-05-20",
  people: [],
  filter: "none",
  createdAt: "2026-05-20T00:00:00.000Z",
  updatedAt: "2026-05-20T00:00:00.000Z"
};

function memory(overrides: Partial<MemoryItem>): MemoryItem {
  return { ...baseMemory, ...overrides };
}

describe("buildPeopleGraph", () => {
  it("returns unique people nodes with counts sorted by count and label", () => {
    const graph = buildPeopleGraph([
      memory({ id: "memory-1", people: ["妈妈", "爸爸", "妈妈"] }),
      memory({ id: "memory-2", people: ["外婆", "爸爸"] }),
      memory({ id: "memory-3", people: ["妈妈"] })
    ]);

    expect(graph.nodes).toEqual([
      { id: "爸爸", label: "爸爸", count: 2 },
      { id: "妈妈", label: "妈妈", count: 2 },
      { id: "外婆", label: "外婆", count: 1 }
    ]);
  });

  it("counts co-appearance links once per memory and sorts them deterministically", () => {
    const graph = buildPeopleGraph([
      memory({ id: "memory-1", people: ["妈妈", "爸爸", "妈妈", "外婆"] }),
      memory({ id: "memory-2", people: ["外婆", "爸爸", "爷爷"] }),
      memory({ id: "memory-3", people: ["爸爸", "妈妈"] })
    ]);

    expect(graph.links).toEqual([
      { source: "爸爸", target: "妈妈", count: 2 },
      { source: "爸爸", target: "外婆", count: 2 },
      { source: "爸爸", target: "爷爷", count: 1 },
      { source: "妈妈", target: "外婆", count: 1 },
      { source: "外婆", target: "爷爷", count: 1 }
    ]);
  });

  it("omits links for memories with fewer than two unique people", () => {
    const graph = buildPeopleGraph([
      memory({ id: "memory-1", people: ["妈妈", "妈妈"] }),
      memory({ id: "memory-2", people: [] })
    ]);

    expect(graph.links).toEqual([]);
  });

  it("keeps links distinct when names contain key separators", () => {
    const graph = buildPeopleGraph([
      memory({ id: "memory-1", people: ["a", "b\u0000c"] }),
      memory({ id: "memory-2", people: ["a\u0000b", "c"] })
    ]);

    expect(graph.links).toEqual([
      { source: "a", target: "b\u0000c", count: 1 },
      { source: "a\u0000b", target: "c", count: 1 }
    ]);
  });
});
