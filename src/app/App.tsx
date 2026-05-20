import { useMemo, useRef, useState } from "react";
import { createLocalMemoryRepository } from "../storage/localMemoryRepository";
import { AppShell } from "./AppShell";
import type { ViewMode } from "./appState";
import { useAlbumController } from "./useAlbumController";
import { useToast } from "./useToast";

export function App() {
  const repository = useMemo(() => createLocalMemoryRepository(), []);
  const controller = useAlbumController(repository);
  const { message, showToast } = useToast();
  const [activeView, setActiveView] = useState<ViewMode>("timeline");
  const photoInputRef = useRef<HTMLInputElement>(null);

  async function handleExport() {
    try {
      await controller.exportAlbum();
      showToast("相册已准备导出，文件保存将在后续任务接入");
    } catch (error) {
      showToast(error instanceof Error ? error.message : "相册导出失败");
    }
  }

  function handleImport() {
    showToast("导入文件选择将在后续任务接入");
  }

  return (
    <AppShell
      title={controller.album.title}
      activeView={activeView}
      memoryCount={controller.memories.length}
      onChangeView={setActiveView}
      onAddPhotos={() => photoInputRef.current?.click()}
      onImport={handleImport}
      onExport={() => {
        void handleExport();
      }}
    >
      <input
        ref={photoInputRef}
        className="visually-hidden"
        type="file"
        accept="image/png,image/jpeg,image/webp,image/gif"
        multiple
      />

      {controller.isLoading ? (
        <section className="panel-state" aria-live="polite">
          正在整理相册...
        </section>
      ) : controller.error ? (
        <section className="panel-state panel-state-error" role="alert">
          {controller.error}
          <button type="button" className="button" onClick={() => void controller.reload()}>
            重试
          </button>
        </section>
      ) : controller.memories.length === 0 ? (
        <section className="empty-state">
          <h2>还没有照片</h2>
          <p>添加第一张照片，开始整理家族回忆。</p>
          <button
            type="button"
            className="button button-primary"
            onClick={() => photoInputRef.current?.click()}
          >
            添加照片
          </button>
        </section>
      ) : (
        <section className="panel-state" aria-live="polite">
          相册数据已接入，下一步实现时间线。
        </section>
      )}

      {message ? (
        <div className="toast" role="status" aria-live="polite">
          {message}
        </div>
      ) : null}
    </AppShell>
  );
}
