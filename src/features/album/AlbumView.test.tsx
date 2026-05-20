import { fireEvent, render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import type { MemoryItem } from "../../domain/memory";
import { AlbumView } from "./AlbumView";

const baseMemory: MemoryItem = {
  id: "memory-1",
  photoDataUrl: "data:image/png;base64,YWJj",
  story: "一起在院子里拍照。",
  date: "2024-02-03",
  people: [],
  filter: "none",
  createdAt: "2024-02-03T00:00:00.000Z",
  updatedAt: "2024-02-03T00:00:00.000Z"
};

function memory(overrides: Partial<MemoryItem>): MemoryItem {
  return {
    ...baseMemory,
    ...overrides
  };
}

describe("AlbumView", () => {
  it("renders an empty album state", () => {
    render(<AlbumView memories={[]} />);

    expect(screen.getByRole("heading", { name: "相册还没有内容" })).toBeInTheDocument();
    expect(screen.getByText("回到时间线添加照片后，这里会生成翻页相册。")).toBeInTheDocument();
  });

  it("renders sorted album pages with page controls", () => {
    render(
      <AlbumView
        memories={[
          memory({
            id: "older",
            date: null,
            story: "",
            people: ["外婆", "妈妈"]
          }),
          memory({
            id: "newer",
            date: "2024-05-06",
            story: "春天的合照。"
          })
        ]}
      />
    );

    expect(screen.getByLabelText("翻页相册")).toBeInTheDocument();
    expect(screen.getByText("春天的合照。")).toBeInTheDocument();
    expect(screen.getByText("1 / 2")).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "上一页" })).toBeDisabled();
    expect(screen.getByRole("button", { name: "下一页" })).toBeEnabled();

    fireEvent.click(screen.getByRole("button", { name: "下一页" }));

    expect(screen.getByText("未标注日期")).toBeInTheDocument();
    expect(screen.getByText("照片记录了这段时光。")).toBeInTheDocument();
    expect(screen.getByText("外婆、妈妈")).toBeInTheDocument();
    expect(screen.getByText("2 / 2")).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "上一页" })).toBeEnabled();
    expect(screen.getByRole("button", { name: "下一页" })).toBeDisabled();
  });
});
