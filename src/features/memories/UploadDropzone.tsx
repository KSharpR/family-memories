import { useRef, useState } from "react";
import type { AppCopy } from "../../app/i18n";
import {
  IMAGE_READ_ERROR_MESSAGE,
  IMAGE_TOO_LARGE_MESSAGE,
  INVALID_IMAGE_TYPE_MESSAGE,
  readFileAsDataUrl,
  validateImageFile
} from "./fileValidation";

interface UploadDropzoneProps {
  copy: AppCopy["upload"];
  errors: AppCopy["errors"];
  actions: AppCopy["actions"];
  onPhotosReady(photos: string[]): void;
  onError(message: string): void;
}

export function UploadDropzone({
  copy,
  errors,
  actions,
  onPhotosReady,
  onError
}: UploadDropzoneProps) {
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
        onError(translateImageError(validation.message, errors));
        continue;
      }

      try {
        photos.push(await readFileAsDataUrl(file));
      } catch (error) {
        onError(
          error instanceof Error
            ? translateImageError(error.message, errors)
            : errors.readImageFailed
        );
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
        <p className="upload-dropzone-title">{copy.title}</p>
        <p className="upload-dropzone-copy">{copy.copy}</p>
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
        {isReading ? copy.reading : actions.addPhotos}
      </button>
    </section>
  );
}

function translateImageError(message: string, errors: AppCopy["errors"]): string {
  if (message === INVALID_IMAGE_TYPE_MESSAGE) {
    return errors.invalidImageType;
  }
  if (message === IMAGE_TOO_LARGE_MESSAGE) {
    return errors.imageTooLarge;
  }
  if (message === IMAGE_READ_ERROR_MESSAGE) {
    return errors.readImageFailed;
  }
  return message;
}
