# Family Memories Web Redesign Design

Date: 2026-05-19
Repository: `KSharpR/family-memories`

## Context

The existing project is a single-file static prototype in `index.html`. It uses Vue 3 from a CDN and includes a broad set of features: local photo memories, story editing, people tags, a generated family graph, album-style browsing, slideshow playback, simulated premium flows, red-packet/payment UI, and simulated collaboration.

The long-term product direction is to build a memoir photo album on the web first, then keep the path open for a future app. Continuing to add features to the current monolithic `index.html` would make future product work harder, so the first stage will migrate the web app into an engineered frontend project.

## Product Direction

First-stage direction:

- Build an engineered web app that can deploy on GitHub Pages.
- Use a local-first data model for the initial release.
- Structure the code as if storage can later move to a cloud API.
- Keep the first release focused on the memoir album experience.
- Do not implement payment, red-packet, premium, account login, cloud sync, or multi-user collaboration in this stage.

The selected product shell is a timeline-first interface. Years and memories are the primary axis, with album, family graph, and slideshow modes available as alternate views.

The selected default visual direction is "warm paper": a restrained memoir-book style using paper-like surfaces, warm neutral backgrounds, dark readable text, and red/gold only as accents. The existing festival red/gold style can return later as an optional theme, but it is not the default product skin.

## Scope

### In Scope

- Photo upload and drag-and-drop upload.
- Memory cards with photo, story, date, and people tags.
- Add, edit, and delete memories.
- Timeline view grouped by year and month.
- Album/book view generated from saved memories.
- Family graph generated from people tags and co-appearance frequency.
- Full-screen slideshow playback.
- Local persistence through a repository layer.
- JSON export and import for backup and restore.
- Desktop and mobile responsive layout.
- GitHub Pages build configuration and README instructions.

### Out of Scope

- Payment and premium subscriptions.
- Red-packet or seasonal paid gift flows.
- Real-time collaboration.
- User accounts and authentication.
- Cloud photo storage.
- Cloud database sync.
- Image/PDF export as a core first-stage requirement.
- Native mobile app implementation.

These out-of-scope items should not appear as active first-stage UI promises. The code may reserve extension points where useful.

## Technical Approach

Use `React + Vite + TypeScript` for the new web app.

Reasons:

- It gives the project a clear build pipeline and GitHub Pages deployment path.
- TypeScript makes the memory data model explicit before cloud and app work begin.
- React's ecosystem is a practical base for future component reuse and possible mobile work.
- A fresh implementation avoids carrying forward the current single-file coupling.

The old `index.html` should be preserved as a legacy reference during migration, not used as the new production entry point.

## Proposed Project Structure

```text
src/
  app/
    App.tsx
    AppShell.tsx
    appState.ts
  domain/
    memory.ts
    album.ts
    repository.ts
  storage/
    localMemoryRepository.ts
    serializers.ts
  features/
    memories/
      TimelineView.tsx
      MemoryCard.tsx
      MemoryEditor.tsx
      UploadDropzone.tsx
    album/
      AlbumView.tsx
      AlbumPage.tsx
    family-tree/
      FamilyTreeView.tsx
      graph.ts
    slideshow/
      SlideshowView.tsx
  styles/
    tokens.css
    global.css
    components.css
docs/
  legacy/
    index.html
```

The exact file names can adjust during implementation if the codebase reveals a cleaner boundary, but the ownership should remain: domain model, storage adapter, features, and shared app shell should stay separate.

## Data Model

### `MemoryItem`

```ts
type MemoryFilter = "none" | "sepia";

interface MemoryItem {
  id: string;
  photoDataUrl: string;
  story: string;
  date: string | null;
  people: string[];
  filter: MemoryFilter;
  createdAt: string;
  updatedAt: string;
}
```

### `Album`

```ts
interface Album {
  id: string;
  title: string;
  memories: MemoryItem[];
  settings: AlbumSettings;
  createdAt: string;
  updatedAt: string;
}
```

### Repository Interface

```ts
interface MemoryRepository {
  loadAlbum(): Promise<Album>;
  saveAlbum(album: Album): Promise<void>;
  addMemory(input: NewMemoryInput): Promise<MemoryItem>;
  updateMemory(id: string, input: UpdateMemoryInput): Promise<MemoryItem>;
  deleteMemory(id: string): Promise<void>;
  exportAlbum(): Promise<string>;
  importAlbum(serialized: string): Promise<Album>;
}
```

The first implementation will use browser local storage. The UI must call the repository interface instead of calling `localStorage` directly. This keeps the future cloud repository path open.

## User Experience

### App Shell

The app opens directly into the usable product, not a marketing landing page. The first viewport should show the album title, primary actions, view tabs, and the timeline content or an empty-state upload prompt.

Primary actions:

- Add photos.
- Import backup.
- Export backup.

Views:

- Timeline.
- Album.
- Family graph.
- Slideshow.

### Timeline

The timeline is the default working view. It groups memories by year and month, shows memory cards, and supports editing and deletion. Empty albums show a clear upload prompt.

### Memory Editor

Uploading a photo opens the editor. The editor supports photo preview, story text, date, people tags, and optional sepia filter. Saving persists through the repository.

### Album View

The album view is generated from saved memories and is optimized for browsing. Editing remains in the timeline/editor flow so the book view can stay calm and focused.

### Family Graph

The family graph is derived from people tags. It represents co-appearance frequency, not legal or genealogical relationships. Labels should avoid overclaiming that the graph is a true family tree.

### Slideshow

The slideshow presents saved photos full screen with story, date, and people metadata. It should handle an empty album with a clear state instead of failing silently.

## Visual System

Default style: warm paper memoir.

Design principles:

- Use warm paper backgrounds and clean white or parchment surfaces.
- Keep red and gold as accents, not dominant page colors.
- Use restrained borders and shadows.
- Use readable typography for Chinese and English content.
- Keep controls clear and practical for repeated use.
- Ensure mobile text and buttons do not overlap or clip.
- Preserve the emotional quality of a family album without making the app feel like a seasonal promotion.

The later festival theme can reuse the old prototype's red/gold, blossom, and celebratory motifs as an optional theme after the base product is stable.

## Error Handling

The first-stage app should handle:

- Non-image uploads.
- Oversized images.
- File read failures.
- Local storage quota failures.
- Import files with invalid JSON.
- Import files with incompatible album shape.
- Empty timeline.
- Empty album view.
- Empty family graph.
- Empty slideshow.

Errors should be shown as clear in-app messages. The app should not expose raw stack traces or leave users in a broken modal.

## Testing And Verification

Implementation should verify:

- The app builds successfully.
- The GitHub Pages asset base works.
- Adding a memory works.
- Editing a memory works.
- Deleting a memory works.
- JSON export and import work.
- Timeline, album, family graph, and slideshow views render.
- Empty states render in all views.
- The main flow works on desktop and mobile viewport sizes.

If automated tests are added in the first stage, prioritize domain serialization, repository behavior, and import validation. Browser verification is still required for the visual and interaction flows.

## Deployment

Deploy target: GitHub Pages for `KSharpR/family-memories`.

Vite should use:

```ts
base: "/family-memories/"
```

The repository should include README instructions for:

- Installing dependencies.
- Running local development.
- Building production assets.
- Deploying or configuring GitHub Pages.

The first stage can use a static build only. No server runtime is required.

## Migration Plan

1. Add the Vite React TypeScript project structure.
2. Preserve the existing `index.html` under `docs/legacy/index.html`.
3. Define domain types and the repository interface.
4. Implement the local repository.
5. Build the timeline view and memory editor.
6. Add import/export.
7. Add album view, family graph view, and slideshow view.
8. Apply the warm paper visual system and responsive layout.
9. Configure GitHub Pages build settings.
10. Update README.
11. Run build and browser verification.

## Spec Self-Review

- Placeholder scan: no unresolved placeholder sections remain.
- Consistency check: the architecture, scope, and migration steps all target the same first-stage local-first React/Vite app.
- Scope check: the first stage is focused on the web MVP and excludes payment, red-packet, accounts, cloud sync, and real-time collaboration.
- Ambiguity check: the family graph is explicitly defined as co-appearance data, not a literal family tree.
