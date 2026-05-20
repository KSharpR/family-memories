import { useState, type ReactNode } from "react";
import type { ViewMode } from "./appState";
import type { AppCopy, Language } from "./i18n";

interface AppShellProps {
  title: string;
  activeView: ViewMode;
  memoryCount: number;
  language: Language;
  copy: AppCopy;
  onChangeView(view: ViewMode): void;
  onChangeLanguage(language: Language): void;
  onAddPhotos(): void;
  onImport(): void;
  onExport(): void;
  children: ReactNode;
}

const views: ViewMode[] = [
  "timeline",
  "album",
  "family-tree",
  "slideshow"
];

export function AppShell({
  title,
  activeView,
  memoryCount,
  language,
  copy,
  onChangeView,
  onChangeLanguage,
  onAddPhotos,
  onImport,
  onExport,
  children
}: AppShellProps) {
  const [isLanguageMenuOpen, setIsLanguageMenuOpen] = useState(false);

  function handleLanguageChange(nextLanguage: Language) {
    onChangeLanguage(nextLanguage);
    setIsLanguageMenuOpen(false);
  }

  return (
    <div className="app-shell">
      <header className="app-topbar">
        <div className="app-title-group">
          <p className="app-kicker">Family Memories</p>
          <h1>{title}</h1>
          <p className="app-summary">{copy.photoCount(memoryCount)}</p>
        </div>
        <div className="app-actions" aria-label={copy.albumActionsLabel}>
          <button type="button" className="button button-primary" onClick={onAddPhotos}>
            {copy.actions.addPhotos}
          </button>
          <button type="button" className="button" onClick={onImport}>
            {copy.actions.import}
          </button>
          <button type="button" className="button" onClick={onExport}>
            {copy.actions.export}
          </button>
          <div className="language-switcher">
            <button
              type="button"
              className="button language-button"
              aria-expanded={isLanguageMenuOpen}
              aria-haspopup="menu"
              aria-label={copy.language.ariaLabel}
              onClick={() => setIsLanguageMenuOpen((isOpen) => !isOpen)}
            >
              <span aria-hidden="true">🌐</span>
              <span>{copy.language.current}</span>
            </button>
            {isLanguageMenuOpen ? (
              <div className="language-menu" role="menu" aria-label={copy.language.menuLabel}>
                <button
                  type="button"
                  className="language-menu-item"
                  role="menuitem"
                  aria-current={language === "zh" ? "true" : undefined}
                  onClick={() => handleLanguageChange("zh")}
                >
                  {copy.language.zh}
                </button>
                <button
                  type="button"
                  className="language-menu-item"
                  role="menuitem"
                  aria-current={language === "en" ? "true" : undefined}
                  onClick={() => handleLanguageChange("en")}
                >
                  {copy.language.en}
                </button>
              </div>
            ) : null}
          </div>
        </div>
      </header>

      <nav className="view-tabs" aria-label={copy.viewTabsLabel}>
        {views.map((view) => (
          <button
            type="button"
            className="view-tab"
            aria-pressed={activeView === view}
            key={view}
            onClick={() => onChangeView(view)}
          >
            {viewLabel(view, copy)}
          </button>
        ))}
      </nav>

      <main className="app-content">{children}</main>
    </div>
  );
}

function viewLabel(view: ViewMode, copy: AppCopy): string {
  if (view === "family-tree") {
    return copy.views.familyTree;
  }
  return copy.views[view];
}
