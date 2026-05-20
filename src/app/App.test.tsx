import { render, screen } from "@testing-library/react";
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
});
