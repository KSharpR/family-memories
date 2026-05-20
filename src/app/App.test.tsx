import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { beforeEach, describe, expect, it } from "vitest";
import { App } from "./App";

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
  beforeEach(() => {
    Object.defineProperty(window, "localStorage", {
      configurable: true,
      value: new MemoryStorage()
    });
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
});
