import { describe, expect, it } from "vitest";
import type { MemoryItem } from "../domain/memory";
import { groupMemoriesByMonth, sortMemories } from "./appState";

const baseMemory: MemoryItem = {
  id: "memory-1",
  photoDataUrl: "data:image/png;base64,YWJj",
  story: "A family memory",
  date: "2024-01-01",
  people: [],
  filter: "none",
  createdAt: "2024-01-01T00:00:00.000Z",
  updatedAt: "2024-01-01T00:00:00.000Z"
};

function memory(overrides: Partial<MemoryItem>): MemoryItem {
  return {
    ...baseMemory,
    ...overrides
  };
}

describe("sortMemories", () => {
  it("sorts dated memories before undated memories in descending order", () => {
    const memories = [
      memory({
        id: "undated-newer-created",
        date: null,
        createdAt: "2025-03-01T00:00:00.000Z"
      }),
      memory({
        id: "older-dated",
        date: "2023-12-24",
        createdAt: "2023-12-24T00:00:00.000Z"
      }),
      memory({
        id: "newer-dated",
        date: "2024-07-02",
        createdAt: "2024-07-02T00:00:00.000Z"
      }),
      memory({
        id: "undated-older-created",
        date: null,
        createdAt: "2022-05-10T00:00:00.000Z"
      })
    ];

    expect(sortMemories(memories).map((item) => item.id)).toEqual([
      "newer-dated",
      "older-dated",
      "undated-newer-created",
      "undated-older-created"
    ]);
  });

  it("does not mutate the source array", () => {
    const memories = [
      memory({ id: "old", date: "2021-01-01" }),
      memory({ id: "new", date: "2024-01-01" })
    ];

    sortMemories(memories);

    expect(memories.map((item) => item.id)).toEqual(["old", "new"]);
  });
});

describe("groupMemoriesByMonth", () => {
  it("groups sorted memories by month with Chinese year-month labels", () => {
    const groups = groupMemoriesByMonth([
      memory({ id: "may-old", date: "2024-05-02" }),
      memory({ id: "undated", date: null, createdAt: "2023-08-01T00:00:00.000Z" }),
      memory({ id: "june", date: "2024-06-15" }),
      memory({ id: "may-new", date: "2024-05-20" })
    ]);

    expect(groups).toEqual([
      {
        key: "2024-06",
        year: "2024",
        month: "06",
        label: "2024年06月",
        memories: [expect.objectContaining({ id: "june" })]
      },
      {
        key: "2024-05",
        year: "2024",
        month: "05",
        label: "2024年05月",
        memories: [
          expect.objectContaining({ id: "may-new" }),
          expect.objectContaining({ id: "may-old" })
        ]
      },
      {
        key: "2023-08",
        year: "2023",
        month: "08",
        label: "2023年08月",
        memories: [expect.objectContaining({ id: "undated" })]
      }
    ]);
  });
});
