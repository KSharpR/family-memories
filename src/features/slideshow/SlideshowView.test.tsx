import { act, cleanup, fireEvent, render, screen } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";
import type { MemoryItem } from "../../domain/memory";
import { SlideshowView } from "./SlideshowView";

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

afterEach(() => {
  cleanup();
  vi.useRealTimers();
});

describe("SlideshowView", () => {
  it("renders an empty slideshow state", () => {
    render(<SlideshowView memories={[]} />);

    expect(screen.getByRole("heading", { name: "还没有可播放的照片" })).toBeInTheDocument();
    expect(screen.getByText("回到时间线添加照片后，可以在这里播放回忆。")).toBeInTheDocument();
  });

  it("renders sorted slides with fallback details and controls", () => {
    render(
      <SlideshowView
        memories={[
          memory({
            id: "older",
            date: null,
            story: "",
            people: ["外婆", "妈妈"],
            filter: "sepia"
          }),
          memory({
            id: "newer",
            date: "2024-05-06",
            story: "春天的合照。"
          })
        ]}
      />
    );

    expect(screen.getByLabelText("幻灯片播放")).toBeInTheDocument();
    expect(screen.getByText("春天的合照。")).toBeInTheDocument();
    expect(screen.getByText("1 / 2")).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "上一张" })).toBeDisabled();
    expect(screen.getByRole("button", { name: "播放" })).toBeEnabled();
    expect(screen.getByRole("button", { name: "下一张" })).toBeEnabled();

    fireEvent.click(screen.getByRole("button", { name: "下一张" }));

    expect(screen.getByText("未标注日期")).toBeInTheDocument();
    expect(screen.getByText("照片记录了这段时光。")).toBeInTheDocument();
    expect(screen.getByText("外婆、妈妈")).toBeInTheDocument();
    expect(screen.getByText("2 / 2")).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "上一张" })).toBeEnabled();
    expect(screen.getByRole("button", { name: "下一张" })).toBeDisabled();
    expect(screen.getByRole("img", { name: "照片记录了这段时光。" })).toHaveClass(
      "photo-filter-sepia"
    );
  });

  it("auto-advances every 4200ms while playing and wraps to the first slide", () => {
    vi.useFakeTimers();

    render(
      <SlideshowView
        memories={[
          memory({ id: "third", date: "2024-03-01", story: "第三张。" }),
          memory({ id: "first", date: "2024-05-01", story: "第一张。" }),
          memory({ id: "second", date: "2024-04-01", story: "第二张。" })
        ]}
      />
    );

    expect(screen.getByText("第一张。")).toBeInTheDocument();

    act(() => {
      vi.advanceTimersByTime(4200);
    });
    expect(screen.getByText("第一张。")).toBeInTheDocument();

    fireEvent.click(screen.getByRole("button", { name: "播放" }));
    act(() => {
      vi.advanceTimersByTime(4200);
    });
    expect(screen.getByText("第二张。")).toBeInTheDocument();

    act(() => {
      vi.advanceTimersByTime(8400);
    });
    expect(screen.getByText("第一张。")).toBeInTheDocument();

    fireEvent.click(screen.getByRole("button", { name: "暂停" }));
    act(() => {
      vi.advanceTimersByTime(4200);
    });
    expect(screen.getByText("第一张。")).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "播放" })).toBeInTheDocument();
  });

  it("does not enter playing state when there is only one slide", () => {
    render(<SlideshowView memories={[memory({ id: "single", story: "唯一一张。" })]} />);

    expect(screen.getByText("唯一一张。")).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "播放" })).toBeDisabled();

    fireEvent.click(screen.getByRole("button", { name: "播放" }));

    expect(screen.queryByRole("button", { name: "暂停" })).not.toBeInTheDocument();
  });

  it("renders captions outside the photo stage for long stories", () => {
    render(
      <SlideshowView
        memories={[
          memory({
            id: "long",
            story: "这是一段很长的照片说明，用来确认字幕不会覆盖在照片上，而是在独立的信息区域里阅读。"
          })
        ]}
      />
    );

    const caption = screen.getByLabelText("幻灯片说明");

    expect(caption).toHaveClass("slideshow-caption");
    expect(caption.closest(".slideshow-stage")).toBeNull();
  });
});
