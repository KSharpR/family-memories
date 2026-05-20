import { cleanup, render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { afterEach, describe, expect, it, vi } from "vitest";
import { MemoryEditor } from "./MemoryEditor";

afterEach(() => cleanup());

describe("MemoryEditor", () => {
  it("exposes an accessible modal dialog that can close with Escape", async () => {
    const onCancel = vi.fn();

    render(
      <MemoryEditor
        mode={{ type: "new", photoDataUrl: "data:image/png;base64,YWJj" }}
        onSaveNew={vi.fn()}
        onSaveEdit={vi.fn()}
        onCancel={onCancel}
        onError={vi.fn()}
      />
    );

    expect(screen.getByRole("dialog", { name: "记录新回忆" })).toHaveAttribute(
      "aria-modal",
      "true"
    );

    await userEvent.keyboard("{Escape}");

    expect(onCancel).toHaveBeenCalledTimes(1);
  });

  it("keeps focus inside the dialog when shift-tabbing from initial focus", async () => {
    render(
      <MemoryEditor
        mode={{ type: "new", photoDataUrl: "data:image/png;base64,YWJj" }}
        onSaveNew={vi.fn()}
        onSaveEdit={vi.fn()}
        onCancel={vi.fn()}
        onError={vi.fn()}
      />
    );

    const dialog = screen.getByRole("dialog", { name: "记录新回忆" });
    expect(dialog).toHaveFocus();

    await userEvent.keyboard("{Shift>}{Tab}{/Shift}");

    expect(screen.getByRole("button", { name: "保存回忆" })).toHaveFocus();
  });
});
