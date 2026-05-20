import { cleanup, fireEvent, render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { App } from "./App";
import { serializeAlbum } from "../storage/serializers";
import type { Album } from "../domain/memory";

class MemoryStorage {
  private values = new Map<string, string>();

  getItem(key: string): string | null {
    return this.values.get(key) ?? null;
  }

  setItem(key: string, value: string): void {
    this.values.set(key, value);
  }

  removeItem(key: string): void {
    this.values.delete(key);
  }

  clear(): void {
    this.values.clear();
  }
}

describe("App", () => {
  let storage: MemoryStorage;

  beforeEach(() => {
    storage = new MemoryStorage();
    Object.defineProperty(window, "localStorage", {
      configurable: true,
      value: storage
    });
    vi.useRealTimers();
  });

  afterEach(() => {
    cleanup();
    vi.restoreAllMocks();
    vi.useRealTimers();
  });

  it("renders the app shell with an empty album", async () => {
    render(<App />);

    expect(
      await screen.findByRole("heading", { name: "家族回忆记录册" })
    ).toBeInTheDocument();
    expect(screen.getByText("Family Memories")).toBeInTheDocument();
    expect(screen.getAllByRole("button", { name: "添加照片" })).toHaveLength(2);
    expect(screen.getByRole("button", { name: "导入" })).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "导出" })).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "时间线" })).toHaveAttribute(
      "aria-pressed",
      "true"
    );
    expect(screen.getByText("还没有照片")).toBeInTheDocument();
  });

  it("opens queued editors for every selected photo", async () => {
    const { container } = render(<App />);
    const fileInput = container.querySelector<HTMLInputElement>('input[type="file"]');

    expect(fileInput).not.toBeNull();
    fireEvent.change(fileInput!, {
      target: {
        files: [
          new File(["first"], "first.png", { type: "image/png" }),
          new File(["second"], "second.png", { type: "image/png" })
        ]
      }
    });

    expect(await screen.findByRole("dialog", { name: "记录新回忆" })).toBeInTheDocument();
    await userEvent.type(screen.getByLabelText("故事"), "第一张");
    await userEvent.click(screen.getByRole("button", { name: "保存回忆" }));

    expect(await screen.findByRole("dialog", { name: "记录新回忆" })).toBeInTheDocument();
    await userEvent.type(screen.getByLabelText("故事"), "第二张");
    await userEvent.click(screen.getByRole("button", { name: "保存回忆" }));

    await waitFor(() => {
      expect(screen.queryByRole("dialog")).not.toBeInTheDocument();
    });
    expect(screen.getByText("第一张")).toBeInTheDocument();
    expect(screen.getByText("第二张")).toBeInTheDocument();
  });

  it("resets editor form state for queued photos with identical data", async () => {
    const { container } = render(<App />);
    const fileInput = container.querySelector<HTMLInputElement>('input[type="file"]');
    const duplicatePayload = "same-image-bytes";

    fireEvent.change(fileInput!, {
      target: {
        files: [
          new File([duplicatePayload], "first.png", { type: "image/png" }),
          new File([duplicatePayload], "second.png", { type: "image/png" })
        ]
      }
    });

    await userEvent.type(await screen.findByLabelText("故事"), "第一张");
    await userEvent.click(screen.getByRole("button", { name: "保存回忆" }));

    expect(await screen.findByRole("dialog", { name: "记录新回忆" })).toBeInTheDocument();
    expect(screen.getByLabelText("故事")).toHaveValue("");
  });

  it("exports the album as a dated JSON download", async () => {
    const today = formatLocalDate(new Date());
    storage.setItem(
      "family-memories:album:v1",
      serializeAlbum({
        ...createTestAlbum(),
        memories: [
          {
            id: "memory-1",
            photoDataUrl: "data:image/png;base64,YWJj",
            story: "一起翻旧照片",
            date: "2026-05-19",
            people: ["奶奶"],
            filter: "sepia",
            createdAt: "2026-05-19T00:00:00.000Z",
            updatedAt: "2026-05-19T00:00:00.000Z"
          }
        ]
      })
    );
    const objectUrls = new Map<string, Blob>();
    Object.defineProperty(URL, "createObjectURL", {
      configurable: true,
      value: vi.fn()
    });
    Object.defineProperty(URL, "revokeObjectURL", {
      configurable: true,
      value: vi.fn()
    });
    const createObjectURL = vi
      .spyOn(URL, "createObjectURL")
      .mockImplementation((blob) => {
        objectUrls.set("blob:album-backup", blob);
        return "blob:album-backup";
      });
    const revokeObjectURL = vi.spyOn(URL, "revokeObjectURL").mockImplementation(() => {});
    const click = vi
      .spyOn(HTMLAnchorElement.prototype, "click")
      .mockImplementation(() => {});

    render(<App />);
    await screen.findByRole("heading", { name: "家族回忆记录册" });
    fireEvent.click(screen.getByRole("button", { name: "导出" }));

    await waitFor(() => expect(createObjectURL).toHaveBeenCalledTimes(1));
    const anchor = click.mock.instances[0];
    const blob = objectUrls.get("blob:album-backup");
    expect(anchor.download).toBe(`family-memories-${today}.json`);
    expect(anchor.href).toBe("blob:album-backup");
    expect(blob?.type).toBe("application/json");
    expect(await readBlobAsText(blob!)).toContain("一起翻旧照片");
    expect(revokeObjectURL).toHaveBeenCalledWith("blob:album-backup");
    expect(await screen.findByText("已导出备份文件")).toBeInTheDocument();
  });

  it("imports selected album JSON and reports success", async () => {
    const imported = serializeAlbum({
      ...createTestAlbum(),
      memories: [
        {
          id: "memory-imported",
          photoDataUrl: "data:image/png;base64,YWJj",
          story: "春节合影",
          date: "2026-02-17",
          people: ["爸爸", "妈妈"],
          filter: "none",
          createdAt: "2026-02-17T00:00:00.000Z",
          updatedAt: "2026-02-17T00:00:00.000Z"
        }
      ]
    });
    const { container } = render(<App />);
    await screen.findByRole("heading", { name: "家族回忆记录册" });

    await userEvent.click(screen.getByRole("button", { name: "导入" }));
    const importInput = container.querySelector<HTMLInputElement>(
      'input[type="file"][accept="application/json,.json"]'
    );
    expect(importInput).not.toBeNull();
    fireEvent.change(importInput!, {
      target: {
        files: [new File([imported], "album.json", { type: "application/json" })]
      }
    });

    expect(await screen.findByText("已导入相册备份")).toBeInTheDocument();
    expect(await screen.findByText("春节合影")).toBeInTheDocument();
  });

  it("reports an error when imported JSON is invalid", async () => {
    const { container } = render(<App />);
    await screen.findByRole("heading", { name: "家族回忆记录册" });

    await userEvent.click(screen.getByRole("button", { name: "导入" }));
    const importInput = container.querySelector<HTMLInputElement>(
      'input[type="file"][accept="application/json,.json"]'
    );
    fireEvent.change(importInput!, {
      target: {
        files: [new File(["not json"], "broken.json", { type: "application/json" })]
      }
    });

    expect(await screen.findByText(/Album import file is not compatible|导入失败/)).toBeInTheDocument();
  });

  it("switches functional UI copy to English while preserving user content", async () => {
    storage.setItem(
      "family-memories:album:v1",
      serializeAlbum({
        ...createTestAlbum(),
        memories: [
          {
            id: "memory-1",
            photoDataUrl: "data:image/png;base64,YWJj",
            story: "春节合影",
            date: "2026-02-17",
            people: ["妈妈"],
            filter: "none",
            createdAt: "2026-02-17T00:00:00.000Z",
            updatedAt: "2026-02-17T00:00:00.000Z"
          }
        ]
      })
    );

    render(<App />);
    await screen.findByRole("heading", { name: "家族回忆记录册" });

    await userEvent.click(screen.getByRole("button", { name: "语言 / Language" }));
    await userEvent.click(screen.getByRole("menuitem", { name: "English" }));

    expect(screen.getByRole("heading", { name: "Family Memory Album" })).toBeInTheDocument();
    expect(screen.getAllByRole("button", { name: "Add Photos" })).toHaveLength(2);
    expect(screen.getByRole("button", { name: "Timeline" })).toHaveAttribute(
      "aria-pressed",
      "true"
    );
    expect(screen.getByText("1 photo recorded")).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Edit" })).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Delete" })).toBeInTheDocument();
    expect(screen.getByText("春节合影")).toBeInTheDocument();
    expect(screen.getByText("妈妈")).toBeInTheDocument();

    await userEvent.click(screen.getByRole("button", { name: "Album" }));
    expect(screen.getByLabelText("Page-style album")).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Previous Page" })).toBeInTheDocument();
    expect(screen.getByText("春节合影")).toBeInTheDocument();

    await userEvent.click(screen.getByRole("button", { name: "People Graph" }));
    expect(screen.getByRole("img", { name: "People co-appearance graph" })).toBeInTheDocument();
    expect(screen.getByText("妈妈: 1 photo")).toBeInTheDocument();

    await userEvent.click(screen.getByRole("button", { name: "Slideshow" }));
    expect(screen.getByLabelText("Slideshow playback")).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Previous" })).toBeInTheDocument();
    expect(screen.getByText("春节合影")).toBeInTheDocument();
    expect(screen.getByText("妈妈")).toBeInTheDocument();
    expect(window.localStorage.getItem("family-memories:language")).toBe("en");
  });
});

function createTestAlbum(): Album {
  return {
    id: "local-album",
    title: "家族回忆记录册",
    settings: { theme: "warm-paper", sortOrder: "desc" },
    createdAt: "2026-05-20T00:00:00.000Z",
    updatedAt: "2026-05-20T00:00:00.000Z",
    memories: []
  };
}

function readBlobAsText(blob: Blob): Promise<string> {
  if ("text" in blob && typeof blob.text === "function") {
    return blob.text();
  }

  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.addEventListener("load", () => {
      resolve(String(reader.result ?? ""));
    });
    reader.addEventListener("error", () => {
      reject(reader.error ?? new Error("Blob read failed"));
    });
    reader.readAsText(blob);
  });
}

function formatLocalDate(date: Date): string {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, "0");
  const day = String(date.getDate()).padStart(2, "0");
  return `${year}-${month}-${day}`;
}
