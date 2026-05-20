const ALLOWED_IMAGE_TYPES = new Set(["image/jpeg", "image/png", "image/webp", "image/gif"]);
const MAX_IMAGE_BYTES = 10 * 1024 * 1024;

export const INVALID_IMAGE_TYPE_MESSAGE = "请上传 JPG、PNG、WebP 或 GIF 图片";
export const IMAGE_TOO_LARGE_MESSAGE = "单张图片不能超过 10MB";
export const IMAGE_READ_ERROR_MESSAGE = "图片读取失败";

export type FileValidationResult = { ok: true } | { ok: false; message: string };

export function validateImageFile(file: File): FileValidationResult {
  if (!ALLOWED_IMAGE_TYPES.has(file.type)) {
    return { ok: false, message: INVALID_IMAGE_TYPE_MESSAGE };
  }

  if (file.size > MAX_IMAGE_BYTES) {
    return { ok: false, message: IMAGE_TOO_LARGE_MESSAGE };
  }

  return { ok: true };
}

export function readFileAsDataUrl(file: File): Promise<string> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();

    reader.onload = () => {
      if (typeof reader.result === "string") {
        resolve(reader.result);
        return;
      }

      reject(new Error(IMAGE_READ_ERROR_MESSAGE));
    };
    reader.onerror = () => {
      reject(new Error(IMAGE_READ_ERROR_MESSAGE));
    };

    reader.readAsDataURL(file);
  });
}
