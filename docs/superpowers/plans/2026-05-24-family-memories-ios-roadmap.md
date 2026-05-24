# Family Memories iOS Roadmap Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bring the native iOS Family Memories app from the current local-first MVP foundation to a reliable trial version, then to a TestFlight-ready private album app.

**Architecture:** Keep the app local-first, with SwiftUI screens backed by small services for photo import, metadata persistence, file storage, and manual backup packages. Do not introduce accounts, app-owned servers, or automatic cloud sync in this roadmap; future sync/storage optimizations should be opt-in and built after the local data loop is stable.

**Tech Stack:** SwiftUI, SwiftData, PhotosUI, FileManager/Application Support storage, ZIPFoundation backup packages, XCTest, XcodeBuildMCP or `xcodebuild`, Git worktree on `ios/native-app`.

---

## Current Baseline

Latest iOS worktree commit:

```text
c8b080c feat: confirm backup imports and enhance album
```

Implemented:

- Native SwiftUI iOS app under `ios/FamilyMemories`.
- Local photo import through the system picker.
- App-private original and thumbnail storage.
- SwiftData metadata persistence.
- Timeline, memory detail, import review, album, and settings tabs.
- Chinese/English UI switching.
- Manual `.familymemories` backup export and import.
- Backup import confirmation before restore.
- Album grid, photo preview, year/person filters, batch selection, and batch delete.
- Unit and UI test coverage for the current core loop.

Not yet complete:

- Trial-ready import polish.
- Backup import summary details.
- Storage usage and cleanup visibility.
- Real-device QA pass.
- TestFlight/archive setup.
- Cross-platform backup compatibility verification against the web MVP.

## Product Principles

- Privacy first: no account, no app-owned server, no automatic upload.
- User controls import/export: only selected photos are copied, and backups happen only after explicit user action.
- Preserve user-written content exactly; UI language switching must not translate user stories, names, or tags.
- Prefer complete local copies for v1 reliability; hybrid storage and iCloud Drive are future enhancements.
- Keep the initial iOS app focused on the core loop: import photos, add memories, browse them, back them up, restore them.

## Roadmap Overview

### Phase 1: Trial-Ready Local MVP Hardening

**Goal:** Make the current iOS app safe enough for hands-on trial use on simulator and at least one real iPhone.

**Primary outcome:** A user can import photos, review/edit metadata, browse timeline/album, export a backup, delete app data, and restore from backup with clear confirmations.

**Tasks:**

- [x] Improve backup import confirmation summary.
- [x] Polish photo import review and partial-failure handling.
- [x] Add storage usage and privacy details to settings.
- [x] Add local data cleanup/reset flows with strong destructive confirmations.
- [x] Add a manual QA checklist for simulator and real-device testing.

**Recommended commit sequence:**

```bash
git commit -m "feat: show backup import summary"
git commit -m "feat: improve photo import review feedback"
git commit -m "feat: show local storage usage"
git commit -m "docs: add ios trial qa checklist"
```

### Phase 2: Timeline And Album Experience Polish

**Goal:** Make browsing memories feel natural as the library grows.

**Primary outcome:** Timeline and album can handle a realistic family photo set with clear browsing, preview, filtering, and editing paths.

**Tasks:**

- [x] Add full-screen photo preview from the album and detail screen.
- [x] Add swipe navigation between previewed album photos.
- [x] Improve timeline cards with clearer date, people, and story hierarchy.
- [x] Add timeline filter/search entry for people and year.
- [x] Add batch tag entry point after batch selection, but keep batch editing simple.
- [x] Preserve current batch delete behavior and confirmation safeguards.

**Deferred from this phase:**

- Pinch-to-zoom image viewer.
- Advanced photo editing.
- Slideshow with music/casting.

### Phase 3: Data Durability And Migration

**Goal:** Reduce the risk of losing or corrupting family memories as the app evolves.

**Primary outcome:** Data model and backup format can change safely across app versions.

**Tasks:**

- [x] Add explicit app data schema versioning.
- [x] Add backup format compatibility tests for current `.familymemories` packages.
- [x] Add import conflict reporting for same memory ID, missing files, and unsupported backup versions.
- [x] Add date-range and memory-count summary to backup validation.
- [x] Add recovery behavior for invalid local records that reference missing image files.
- [x] Document the backup package contract in `docs/`.

### Phase 4: Real Device And TestFlight Preparation

**Goal:** Prepare the iOS app for controlled external trial use.

**Primary outcome:** The app can be installed and tested through a standard Apple distribution path.

**Tasks:**

- [ ] Configure signing with the selected Apple Developer team.
- [x] Add app icon and launch screen polish.
- [x] Review `Info.plist` privacy strings and document actual photo/file behavior.
- [ ] Run real-device import/export/restore testing.
- [ ] Create an Archive build.
- [x] Prepare TestFlight internal testing notes.
- [x] Add a release checklist covering privacy, backup, restore, and destructive actions.

### Phase 5: Web Compatibility And Migration

**Goal:** Keep the web MVP and iOS app aligned enough for future cross-platform use.

**Primary outcome:** A backup exported from one platform has a clear migration path to the other, even if perfect round-trip support is not immediate.

**Tasks:**

- [ ] Compare iOS `.familymemories` package shape with the current web export shape.
- [ ] Add adapter tests for compatible memory fields.
- [ ] Decide whether thumbnails are required in cross-platform packages or can be regenerated.
- [ ] Write a migration note for users moving between web and iOS.
- [ ] Keep web deployment stable as a preview/demo surface, without adding accounts or server storage.

### Phase 6: Future Enhancements Backlog

These are intentionally not part of the first trial version:

- Hybrid photo storage mode to reduce duplicate storage usage.
- iCloud Drive package support as an opt-in user-owned sync path.
- People profiles, family relationships, places, events, and archive-style metadata.
- Slideshow and TV/casting-oriented playback.
- Advanced photo editing.
- Android app.
- Desktop app.
- Full cross-platform rewrite after the iOS model is stable.

## Immediate Next Sprint

### Task 1: Backup Import Summary

**Files:**

- Modify: `ios/FamilyMemories/FamilyMemories/Backup/BackupPackageService.swift`
- Modify: `ios/FamilyMemories/FamilyMemories/App/AppRootView.swift`
- Modify: `ios/FamilyMemories/FamilyMemories/Localization/Localizable.xcstrings`
- Test: `ios/FamilyMemories/FamilyMemoriesTests/BackupPackageServiceTests.swift`

**Acceptance criteria:**

- Import confirmation shows memory count.
- Import confirmation shows backup creation date.
- Import confirmation explains merge behavior and same-ID overwrite behavior.
- Invalid packages still stop before any local mutation.
- Existing backup tests pass.

**Verification:**

```bash
xcodebuild \
  -project ios/FamilyMemories/FamilyMemories.xcodeproj \
  -scheme FamilyMemories \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  -derivedDataPath /Volumes/p310-1/DerivedData/FamilyMemories \
  -only-testing:FamilyMemoriesTests/BackupPackageServiceTests \
  test
```

### Task 2: Import Review Feedback

**Files:**

- Modify: `ios/FamilyMemories/FamilyMemories/Features/ImportReview/ImportReviewView.swift`
- Modify: `ios/FamilyMemories/FamilyMemories/Importing/PhotoImportService.swift`
- Modify: `ios/FamilyMemories/FamilyMemories/Localization/Localizable.xcstrings`
- Test: `ios/FamilyMemories/FamilyMemoriesTests/PhotoImportServiceTests.swift`

**Acceptance criteria:**

- Successful imports are clearly separated from failed imports.
- Failed imports show a user-readable reason.
- Users can still save valid imported photos when some photos fail.
- User-entered story, people, and date data are preserved exactly.

**Verification:**

```bash
xcodebuild \
  -project ios/FamilyMemories/FamilyMemories.xcodeproj \
  -scheme FamilyMemories \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  -derivedDataPath /Volumes/p310-1/DerivedData/FamilyMemories \
  -only-testing:FamilyMemoriesTests/PhotoImportServiceTests \
  test
```

### Task 3: Storage Usage In Settings

**Files:**

- Create: `ios/FamilyMemories/FamilyMemories/Storage/StorageUsageService.swift`
- Modify: `ios/FamilyMemories/FamilyMemories/App/AppEnvironment.swift`
- Modify: `ios/FamilyMemories/FamilyMemories/Features/Settings/SettingsView.swift`
- Modify: `ios/FamilyMemories/FamilyMemories/Localization/Localizable.xcstrings`
- Test: `ios/FamilyMemories/FamilyMemoriesTests/StorageUsageServiceTests.swift`

**Acceptance criteria:**

- Settings shows total local storage used by Family Memories.
- Settings separates originals, thumbnails, backups, and metadata when practical.
- The screen explains that selected photos are copied into app-private local storage.
- No cleanup action is hidden behind ambiguous wording.

**Verification:**

```bash
xcodebuild \
  -project ios/FamilyMemories/FamilyMemories.xcodeproj \
  -scheme FamilyMemories \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  -derivedDataPath /Volumes/p310-1/DerivedData/FamilyMemories \
  -only-testing:FamilyMemoriesTests/StorageUsageServiceTests \
  test
```

### Task 4: Trial QA Checklist

**Files:**

- Create: `docs/ios-trial-qa-checklist.md`
- Modify: `README.md`

**Acceptance criteria:**

- Checklist includes simulator setup.
- Checklist includes real-device photo import.
- Checklist includes backup export/import.
- Checklist includes language switching.
- Checklist includes destructive delete/reset flows.
- Checklist records known Simulator `preflight busy` recovery steps.

**Verification:**

```bash
git diff --check
```

## Standard Verification Before Each Phase Completion

Run static checks:

```bash
jq empty ios/FamilyMemories/FamilyMemories/Localization/Localizable.xcstrings
plutil -lint ios/FamilyMemories/FamilyMemories.xcodeproj/project.pbxproj ios/FamilyMemories/FamilyMemories/App/Info.plist
git diff --check
```

Run unit tests:

```bash
xcodebuild \
  -project ios/FamilyMemories/FamilyMemories.xcodeproj \
  -scheme FamilyMemories \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  -derivedDataPath /Volumes/p310-1/DerivedData/FamilyMemories \
  -only-testing:FamilyMemoriesTests \
  test
```

Run UI smoke tests:

```bash
xcodebuild \
  -project ios/FamilyMemories/FamilyMemories.xcodeproj \
  -scheme FamilyMemories \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  -derivedDataPath /Volumes/p310-1/DerivedData/FamilyMemories \
  -only-testing:FamilyMemoriesUITests \
  test
```

If Simulator returns `Application failed preflight checks` or `Busy`, recover with:

```bash
xcrun simctl shutdown 7FD29A7D-AA28-4BB9-91F7-C3A0FD014F50 >/dev/null 2>&1 || true
xcrun simctl erase 7FD29A7D-AA28-4BB9-91F7-C3A0FD014F50
```

Then rerun the failed command.

## Recommended Execution Mode

Use Subagent-Driven execution for the immediate next sprint:

- One worker for backup import summary.
- One worker for import review feedback.
- One worker for storage usage/settings.
- One worker for QA checklist/docs.

Review and merge one task at a time. Keep commits small and test evidence attached to each commit summary.
