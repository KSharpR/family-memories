# Family Memories

Family Memories is a local-first web app for collecting and revisiting family photos, stories, dates, and people tags. The first MVP stores album data in the browser so families can organize memories without a backend service.

## First-stage Scope

- Upload JPG, PNG, WebP, and GIF photos from the browser.
- Add stories, dates, people tags, and an optional sepia treatment.
- Browse memories in a timeline grouped by month.
- Read memories in a page-style album view.
- Explore people connections in a lightweight family graph.
- Play memories as a slideshow.
- Import and export the album as a JSON backup file.

## Development

Install dependencies:

```bash
npm install
```

Run the local Vite dev server:

```bash
npm run dev
```

## Tests

Run the Vitest suite:

```bash
npm test
```

## Build

Create a production build:

```bash
npm run build
```

The Vite base path is configured as `/family-memories/` for GitHub Pages deployment.

## GitHub Pages

The Pages workflow in `.github/workflows/deploy.yml` builds the app on pushes to `main` and on manual `workflow_dispatch` runs. It installs with `npm ci`, runs `npm run build`, uploads `dist`, and deploys through GitHub Pages.

## Legacy Prototype

The earlier static prototype is preserved at `docs/legacy/index.html`.

## iOS App

The native iOS app lives in `ios/FamilyMemories`.

### Requirements

- Xcode 26.5 or newer for the current local setup
- An available iPhone simulator
- No account or server is required for local development

### Build And Test

```bash
xcodebuild \
  -project ios/FamilyMemories/FamilyMemories.xcodeproj \
  -scheme FamilyMemories \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  -derivedDataPath /Volumes/p310-1/DerivedData/FamilyMemories \
  test
```

### Privacy Model

The iOS app is local-first. It uses the system photo picker, copies only selected photos into app-private storage, and does not use app-owned servers or automatic cloud upload. Manual backups are created only when the user exports them.
