# Family Memories iOS App Design

Date: 2026-05-21
Repository: `KSharpR/family-memories`

## Context

The project currently has a deployed web MVP for a family memoir photo album. It is local-first, has no accounts or server storage, and supports timeline memories, album reading, people co-appearance, slideshow, backup import/export, and Chinese/English UI switching.

The next product step is a native iOS app. The main reason to prioritize iOS is that the user's most important photos already live on the phone, and native iOS gives the best path for photo picking, private local storage, file export, AirDrop, Files integration, and later iCloud Drive support.

The iOS app should not introduce accounts, app-owned servers, or automatic cloud sync in the first version. The privacy model is part of the product: family photos, stories, people tags, and dates stay on the user's device unless the user intentionally exports or shares them.

## Product Direction

The iOS first version will combine:

- A private album organization tool.
- A memoir-style reading album.

The app is not intended to replace Apple Photos. It lets users select meaningful photos from their phone, copy them into a private family memory album, and enrich them with story, people, and date metadata.

The selected direction combines two approaches:

- Native SwiftUI implementation for the iOS user experience and system integrations.
- Web-compatible backup data where practical, so the project can migrate data across platforms later.

The iOS app's internal architecture should serve the native app first. Export and import adapters should carry compatibility with the web data model where it is useful, without forcing the iOS model to mirror the current web implementation exactly.

## Scope

### In Scope

- Native SwiftUI iOS app.
- System photo picker import with multi-select.
- Copy imported photos into the app's private local storage.
- Generate thumbnails for lists and timeline performance.
- Read photo capture date when available and use it as the default memory date.
- Let users manually edit or label the date.
- Let users add and edit story text.
- Let users add and edit people tags.
- Timeline-first browsing grouped by year and month.
- Single-memory detail view for reading and editing.
- Album reader view as a secondary reading experience.
- Manual backup package export.
- Manual backup package import.
- Chinese/English UI switching.
- Preserve user-entered content exactly as written, without translation.
- Offline use without an account or server.

### Out of Scope

- User accounts.
- App-owned backend servers.
- Cloud database storage.
- Automatic cloud sync.
- iCloud Drive file package sync.
- Payment or subscription flows.
- Collaboration features.
- Social sharing or public community features.
- Family archive database with structured people profiles, events, places, and relationship history.
- Advanced photo editing such as crop, rotate, color correction, and multi-filter editing.
- Slideshow playback.
- Android, web rewrite, or desktop app implementation.

### Recorded Future Enhancements

- Hybrid photo storage mode to reduce storage use.
- Storage usage screen and cleanup tools.
- iCloud Drive file package support.
- Cross-device migration beyond manual backup files.
- Family archive features, including people profiles, locations, events, and richer relationship views.
- Slideshow, casting, music, and playback controls.
- Advanced photo editing.
- Cross-platform clients after the iOS model is stable.

## Privacy Model

The first version is local-first and device-owned:

- No account is required.
- No app-owned server is used.
- No automatic upload occurs.
- No background scan of the user's photo library occurs.
- The app uses the system photo picker so the user explicitly chooses which photos to import.
- Only selected photos are copied into the app.
- Family stories, people tags, dates, and other metadata remain local unless the user exports them.

The app should explain this before first import in plain language. The privacy copy should avoid vague promises and state the actual behavior: selected photos are copied into the app's private storage on this device, and backups are only created when the user exports them.

## Photo Storage

Initial implementation uses complete local copies:

- Imported originals are copied into the app's private directory.
- The app does not rely on Apple Photos keeping the original asset available.
- Deleting the source photo from Apple Photos does not remove the memory inside Family Memories.
- Thumbnails are generated and stored separately for timeline and list rendering.

This is intentionally more storage-heavy than referencing Apple Photos assets, but it is clearer and safer for a memoir app. A future hybrid storage mode can add space-saving options after the first version is reliable.

Recommended file layout:

```text
Application Support/
  FamilyMemories/
    Originals/
    Thumbnails/
    Backups/
```

The implementation may use `Documents` for exported user-visible files, but managed app data should live under Application Support.

## Data Model

First-version model:

```text
Memory
- id
- originalFilename
- originalPath
- thumbnailPath
- story
- date
- people: [String]
- filter
- createdAt
- updatedAt
- sourceCreatedAt
- sourceAssetIdentifier optional
```

Field meaning:

- `id` is stable and drives database records, files, backups, and UI identity.
- `date` is the user-facing memory date and can be edited.
- `sourceCreatedAt` is the original capture date read from photo metadata when available.
- `sourceAssetIdentifier` can record origin but must not be required to load a memory.
- `people` is a list of user-entered string tags in the first version.
- `filter` is retained as a compatibility and future extension field, but advanced photo editing is not in scope.

People tags should be normalized by trimming whitespace, removing empty values, and deduplicating exact matches. First version does not need a separate person table.

## Backup Format

The first version uses a manual full backup package.

Package extension:

```text
.familymemories
```

Implementation format:

```text
family-memories-backup.familymemories
  manifest.json
  memories.json
  originals/
  thumbnails/ or enough metadata to rebuild thumbnails
```

`manifest.json` should include:

```text
- appName
- backupVersion
- createdAt
- memoryCount
- locale
- minimumSupportedAppVersion
```

`memories.json` should remain close enough to the web export shape to support future migration, but an adapter layer should perform conversion. The app's SwiftData or SQLite entities should not be forced to match the backup JSON one-to-one.

Import behavior:

- Validate the package before modifying local data.
- Validate manifest version and required files.
- Validate image types and memory records.
- Show an import summary before applying, including memory count and date range when possible.
- Default to append import.
- Avoid destructive overwrite as the default path.

An advanced replace-all import can be added later, but it should require explicit confirmation.

## Core Screens

### Timeline

The timeline is the default home screen.

It should:

- Group memories by year and month.
- Show thumbnail, date, story preview, and people tags.
- Provide the main import action.
- Support opening memory detail.
- Handle an empty album with a clear first-import action.

### Memory Detail

The detail view is for reading and editing a single memory.

It should:

- Show the photo prominently.
- Show story, date, and people.
- Let users edit story, date, and people.
- Let users delete the memory.
- Keep editing controls practical and calm rather than visually busy.

### Import Review

The import flow should support batch import without forcing users to complete every field immediately.

It should:

- Copy selected photos.
- Generate thumbnails.
- Read capture date where available.
- Let users review imported items one by one.
- Allow story, people, and date edits.
- Allow skipping details and finishing later.
- Show partial failures without discarding successful imports.

### Album Reader

The album reader is the secondary emotional reading view.

It should:

- Present one memory per page or screen.
- Use a simple SwiftUI paging experience.
- Show photo, story, date, and people.
- Avoid complex editing controls inside the reading flow.
- Avoid complex page-turn animation in the first version.

### Settings And Backup

Settings should include:

- Language switch.
- Export backup package.
- Import backup package.
- Privacy and local storage explanation.
- Backup reminder copy.

Future settings can add storage usage, cleanup, iCloud Drive file package, and space-saving mode.

## Navigation

iPhone first version uses a bottom tab structure:

- Timeline.
- Album.
- Settings.

iPad can later use a sidebar layout, but iPad-specific optimization is not a first-version requirement.

## Platform Target

The first implementation targets iOS 17 and newer. This keeps the app aligned with SwiftUI, `PhotosPicker`, SwiftData, and modern localization APIs while avoiding extra compatibility work in the first version.

Older iOS support can be revisited after the local import, storage, backup, and restore loop is stable.

## Technology

Recommended stack:

- SwiftUI for the UI.
- `PhotosPicker` for user-selected photo import.
- SwiftData for the first local metadata store.
- FileManager for private photo, thumbnail, and backup file management.
- A small backup/import service that creates and validates `.familymemories` packages.
- Localized string resources for Chinese and English.

Architecture:

```text
UI layer
  SwiftUI views

State layer
  Observable view models

Domain layer
  Memory, Album, BackupManifest, validation rules

Storage layer
  Local metadata store, file storage, backup import/export
```

UI views should not copy files or write database records directly. Import, storage, backup, and validation should live behind services with narrow interfaces so they can be tested without rendering SwiftUI views.

If implementation reveals a concrete SwiftData blocker, the project can switch the metadata store to SQLite before continuing. That decision should be documented in the implementation plan rather than handled ad hoc during feature work.

## Error Handling

Photo import:

- Single-photo failure should not abort the entire batch.
- The app should report how many photos succeeded and failed.
- Successful imports should remain available.
- Failed imports should be retryable when possible.

Storage:

- The app should handle file write failure.
- It should avoid creating database records for missing files.
- It should avoid leaving orphaned files where practical.
- Storage-space failures should produce user-readable messages.

Backup:

- Invalid or unsupported backups should not modify existing data.
- The app should validate manifest and memory records before import.
- Import should show a confirmation step.

Permissions and system cancellation:

- If the user cancels photo selection or sharing, the app should return quietly.
- Export/share failures should show a clear retryable error.

## Testing Strategy

### Unit Tests

- Memory model conversion.
- People tag normalization.
- Date extraction fallback and user date override rules.
- Backup manifest validation.
- Backup package structure validation.
- Append import and duplicate handling.

### Integration Tests

- Batch import creates original files, thumbnails, and metadata records.
- Delete memory removes or schedules cleanup of associated files.
- Exported backup can be imported into an empty local store.
- Invalid backup does not modify current data.
- Language switching changes UI copy but preserves user-entered content.

### UI Tests

- First launch empty state.
- Import flow.
- Edit story, date, and people.
- Timeline grouping.
- Album reader paging.
- Settings language switch.
- Export and import entry points.

### Manual Device Testing

- Import 20 to 50 real photos on a real iPhone or iPad. If the first pass is on iPad, repeat iPhone small-screen/layout smoke testing before claiming iPhone-ready distribution.
- Relaunch app and verify data persists.
- Use Airplane Mode and verify the app remains usable.
- Delete source photos from Apple Photos and verify imported memories still display.
- Export backup through the share sheet.
- Save backup to Files.
- Reinstall or clear data, then restore through the backup package.

## Acceptance Criteria

The first iOS version is ready when:

- A user can import multiple photos from Apple Photos.
- Imported photos are copied into app-private storage.
- The app can read a default capture date when metadata is available.
- The user can edit story, people, and date.
- The timeline groups memories by year and month.
- The user can open and edit memory details.
- The user can browse a simple album reader.
- The user can export a complete backup package.
- The user can import a valid backup package.
- The app runs offline without accounts or servers.
- Chinese and English UI copy can be switched.
- User-entered content is never translated automatically.
- Basic real-device testing finds no obvious data loss path.

## Implementation Notes

The initial implementation should start with a small SwiftUI project that proves the full local loop:

1. Import photos.
2. Store originals and thumbnails.
3. Store metadata.
4. Display timeline.
5. Edit a memory.
6. Export a backup.
7. Import the backup.

Only after that loop is stable should the album reader and polish work expand. This order reduces the risk of building attractive UI on top of weak persistence.
