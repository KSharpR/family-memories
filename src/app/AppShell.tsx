import type { ReactNode } from "react";
import type { ViewMode } from "./appState";

interface AppShellProps {
  title: string;
  activeView: ViewMode;
  memoryCount: number;
  onChangeView(view: ViewMode): void;
  onAddPhotos(): void;
  onImport(): void;
  onExport(): void;
  children: ReactNode;
}

const views: Array<{ value: ViewMode; label: string }> = [
  { value: "timeline", label: "时间线" },
  { value: "album", label: "翻页相册" },
  { value: "family-tree", label: "人物关系" },
  { value: "slideshow", label: "幻灯片" }
];

export function AppShell({
  title,
  activeView,
  memoryCount,
  onChangeView,
  onAddPhotos,
  onImport,
  onExport,
  children
}: AppShellProps) {
  return (
    <div className="app-shell">
      <header className="app-topbar">
        <div className="app-title-group">
          <p className="app-kicker">Family Memories</p>
          <h1>{title}</h1>
          <p className="app-summary">{memoryCount} 张照片正在记录</p>
        </div>
        <div className="app-actions" aria-label="相册操作">
          <button type="button" className="button button-primary" onClick={onAddPhotos}>
            添加照片
          </button>
          <button type="button" className="button" onClick={onImport}>
            导入
          </button>
          <button type="button" className="button" onClick={onExport}>
            导出
          </button>
        </div>
      </header>

      <nav className="view-tabs" aria-label="相册视图">
        {views.map((view) => (
          <button
            type="button"
            className="view-tab"
            aria-pressed={activeView === view.value}
            key={view.value}
            onClick={() => onChangeView(view.value)}
          >
            {view.label}
          </button>
        ))}
      </nav>

      <main className="app-content">{children}</main>
    </div>
  );
}
