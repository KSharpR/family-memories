import { useRef, useState } from "react";
import { readFileAsDataUrl, validateImageFile } from "./fileValidation";

interface UploadDropzoneProps {
  onPhotosReady(photos: string[]): void;
  onError(message: string): void;
}

export function UploadDropzone({ onPhotosReady, onError }: UploadDropzoneProps) {
  const inputRef = useRef<HTMLInputElement>(null);
  const [isDragging, setIsDragging] = useState(false);
  const [isReading, setIsReading] = useState(false);

  async function processFiles(fileList: FileList | File[]) {
    const files = Array.from(fileList);

    if (files.length === 0) {
      return;
    }

    setIsReading(true);
    const photos: string[] = [];

    for (const file of files) {
      const validation = validateImageFile(file);
      if (!validation.ok) {
        onError(validation.message);
        continue;
      }

      try {
        photos.push(await readFileAsDataUrl(file));
      } catch (error) {
        onError(error instanceof Error ? error.message : "图片读取失败");
      }
    }

    setIsReading(false);

    if (photos.length > 0) {
      onPhotosReady(photos);
    }
  }

  function resetInput() {
    if (inputRef.current) {
      inputRef.current.value = "";
    }
  }

  return (
    <section
      className={`upload-dropzone${isDragging ? " upload-dropzone-active" : ""}`}
      onClick={() => inputRef.current?.click()}
      onDragEnter={(event) => {
        event.preventDefault();
        setIsDragging(true);
      }}
      onDragOver={(event) => {
        event.preventDefault();
      }}
      onDragLeave={(event) => {
        event.preventDefault();
        setIsDragging(false);
      }}
      onDrop={(event) => {
        event.preventDefault();
        setIsDragging(false);
        void processFiles(event.dataTransfer.files);
      }}
    >
      <input
        ref={inputRef}
        className="visually-hidden"
        type="file"
        accept="image/png,image/jpeg,image/webp,image/gif"
        multiple
        onChange={(event) => {
          const { files } = event.currentTarget;
          if (files) {
            void processFiles(files);
          }
          resetInput();
        }}
      />
      <div>
        <p className="upload-dropzone-title">把照片拖到这里</p>
        <p className="upload-dropzone-copy">支持 JPG、PNG、WebP、GIF，单张不超过 10MB。</p>
      </div>
      <button
        type="button"
        className="button button-primary"
        disabled={isReading}
        onClick={(event) => {
          event.stopPropagation();
          inputRef.current?.click();
        }}
      >
        {isReading ? "读取中..." : "添加照片"}
      </button>
    </section>
  );
}
