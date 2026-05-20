import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import { App } from "./App";

describe("App", () => {
  it("renders the migration welcome panel", () => {
    render(<App />);

    expect(
      screen.getByRole("heading", { name: "家族回忆记录册" })
    ).toBeInTheDocument();
    expect(screen.getByText("Family Memories")).toBeInTheDocument();
    expect(
      screen.getByText("工程化迁移已启动。下一步接入本地相册数据模型。")
    ).toBeInTheDocument();
  });
});
