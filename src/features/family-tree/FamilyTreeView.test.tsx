import { cleanup, render, screen, within } from "@testing-library/react";
import { afterEach, describe, expect, it } from "vitest";
import type { MemoryItem } from "../../domain/memory";
import { FamilyTreeView } from "./FamilyTreeView";

afterEach(() => cleanup());

const baseMemory: MemoryItem = {
  id: "memory-1",
  photoDataUrl: "data:image/png;base64,YWJj",
  story: "",
  date: "2026-05-20",
  people: [],
  filter: "none",
  createdAt: "2026-05-20T00:00:00.000Z",
  updatedAt: "2026-05-20T00:00:00.000Z"
};

function memory(id: string, people: string[]): MemoryItem {
  return {
    ...baseMemory,
    id,
    people
  };
}

describe("FamilyTreeView", () => {
  it("renders an empty people graph state", () => {
    render(<FamilyTreeView memories={[]} />);

    expect(screen.getByRole("heading", { name: "还没有人物关系" })).toBeInTheDocument();
    expect(screen.getByText("在照片中添加人物标签后，这里会显示同框关系。")).toBeInTheDocument();
  });

  it("renders an accessible relationship summary", () => {
    render(
      <FamilyTreeView
        memories={[
          memory("a", ["奶奶", "我"]),
          memory("b", ["奶奶", "妈妈", "我"])
        ]}
      />
    );

    expect(screen.getByRole("img", { name: "人物同框关系图" })).toBeInTheDocument();
    const summary = screen.getByRole("list", { name: "人物同框关系摘要" });

    expect(within(summary).getByText("奶奶：2 张照片")).toBeInTheDocument();
    expect(within(summary).getByText("奶奶 和 我：2 次同框")).toBeInTheDocument();
    expect(within(summary).getByText("妈妈 和 奶奶：1 次同框")).toBeInTheDocument();
  });

  it("keeps many-node graphs readable with non-overlapping circles", () => {
    const people = Array.from({ length: 40 }, (_, index) => `人物${String(index + 1).padStart(2, "0")}`);

    render(<FamilyTreeView memories={[memory("large-group", people)]} />);

    const circles = screen
      .getAllByTestId("family-tree-node-circle")
      .map((circle) => ({
        x: Number(circle.getAttribute("cx")),
        y: Number(circle.getAttribute("cy")),
        r: Number(circle.getAttribute("r"))
      }));

    for (let firstIndex = 0; firstIndex < circles.length; firstIndex += 1) {
      for (let secondIndex = firstIndex + 1; secondIndex < circles.length; secondIndex += 1) {
        const first = circles[firstIndex];
        const second = circles[secondIndex];
        const distance = Math.hypot(first.x - second.x, first.y - second.y);

        expect(distance).toBeGreaterThanOrEqual(first.r + second.r - 0.001);
      }
    }

    expect(screen.getByText("人物01")).toBeInTheDocument();
    expect(screen.getByText("人物40")).toBeInTheDocument();
  });

  it("uses unambiguous keys for relationships with separators in names", () => {
    render(
      <FamilyTreeView
        memories={[
          memory("a", ["a-b", "c"]),
          memory("b", ["a", "b-c"])
        ]}
      />
    );

    const lines = screen.getAllByTestId("family-tree-link");

    expect(lines).toHaveLength(2);
    expect(new Set(lines.map((line) => line.getAttribute("data-link-key"))).size).toBe(2);
  });
});
