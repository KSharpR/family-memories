import { describe, expect, it } from "vitest";
import { validateImageFile } from "./fileValidation";

function makeFile(name: string, type: string, size: number): File {
  return new File(["x".repeat(size)], name, { type });
}

describe("file validation", () => {
  it("accepts small image files", () => {
    expect(validateImageFile(makeFile("family.png", "image/png", 1024))).toEqual({
      ok: true
    });
  });

  it("rejects non-image files", () => {
    expect(validateImageFile(makeFile("notes.txt", "text/plain", 1024))).toEqual({
      ok: false,
      message: "请上传 JPG、PNG、WebP 或 GIF 图片"
    });
  });

  it("rejects images over ten megabytes", () => {
    expect(validateImageFile(makeFile("huge.jpg", "image/jpeg", 11 * 1024 * 1024))).toEqual({
      ok: false,
      message: "单张图片不能超过 10MB"
    });
  });
});
