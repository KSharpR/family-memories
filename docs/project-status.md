# Project Status Handoff

Last updated: 2026-07-07

This file is the restart point for the Family Memories project after the current chat closes. Read it first, then continue from the main repo below.

## Repository State

- Repository: `/Volumes/p310/Codex/projects/family-memories`
- Active workspace: `/Volumes/p310/Codex/projects/family-memories` (main repo root)
- Branch: `main`
- Latest implementation commit before this handoff: `c9fa230 feat: confirm web json imports on ios`
- Current product direction: local-first family memoir photo album, web first for preview, native iOS first for mobile, no account/server/cloud sync in the initial product.

> The previous iOS work was tracked on branch `ios/native-app` (worktree `.worktrees/ios-native-app`). That branch and worktree are **no longer active**. All current iOS work lives on `main` at this repository root. Do not `cd` into `.worktrees/ios-native-app` or `../family-memories-ios-app`.

**Current worktree inventory:**

| Path | Branch | HEAD |
|------|--------|------|
| `main repo root` | `main` | `c9fa230` |
| `.worktrees/web-familymemories-import` | `feature/web-familymemories-import` | `c9fa230` |
| `.worktrees/web-redesign-implementation` | `web-redesign-implementation` | `5e67ff3` |

## Local Tooling

- Xcode: 26.5, build `17F42`
- Active developer directory: `/Volumes/p310-1/Applications/Xcode.app/Contents/Developer`
- Xcode app location: `/Volumes/p310-1/Applications/Xcode.app`
- Project DerivedData path used by commands: `/Volumes/p310-1/DerivedData/FamilyMemories`
- Main simulator used for verification: iPhone 17 Pro, iOS 26.5, UUID `7FD29A7D-AA28-4BB9-91F7-C3A0FD014F50`

Disk usage measured on 2026-07-03:

- `/Volumes/p310-1/Applications/Xcode.app`: 4.0G
- `/Volumes/p310-1/DerivedData`: 360M
- `/Users/jinsiqi/Library/Developer/Xcode/DerivedData`: 161M
- `/Users/jinsiqi/Library/Developer/CoreSimulator`: 3.6G
- `/Volumes/p310-1/Developer/CoreSimulator`: 6.7G

Note: Xcode itself and the active project DerivedData are on P310-1. Simulator data is still split between the user Library path and the P310-1 sparsebundle migration path, so do not assume Simulator storage is fully consolidated.

## Implemented Product State

Web app:

- React/Vite local-first web MVP with browser-local album storage.
- Photo upload, stories, dates, people tags, optional sepia treatment.
- Timeline, album, family tree, slideshow, import/export, and Chinese/English UI switching.
- GitHub Pages workflow remains the web preview/deployment path.

iOS app:

- Native SwiftUI app under `ios/FamilyMemories`.
- Local-first architecture using SwiftUI, SwiftData, PhotosUI, FileManager/Application Support, ZIPFoundation, and XCTest.
- App-private original and thumbnail storage for selected photos.
- Timeline, memory detail, import review, album, and settings tabs.
- Chinese/English UI switching for functional UI copy. User-entered stories, names, tags, and notes are preserved as written.
- Manual `.familymemories` backup export/import with validation, schema versioning, import summary, same-ID conflict reporting, and confirmation before restore.
- Web JSON import path from current/legacy web exports into the iOS local library, with pre-import confirmation summary showing memory count, same-ID overwrite count, and date range.
- Storage usage visibility in settings.
- Local data reset flow with destructive confirmation.
- Album enhancements: full-screen photo preview, swipe navigation, year/person filters, batch select/delete, and batch tag entry.
- Memory library integrity repair for records whose image files are missing.
- App icon assets and privacy manifest have been added.
- Release and trial QA checklists exist under `docs/`.

## Roadmap Status

- Phase 1, Trial-Ready Local MVP Hardening: complete.
- Phase 2, Timeline And Album Experience Polish: complete for the current target scope.
- Phase 3, Data Durability And Migration: complete for the current target scope.
- Phase 4, Real Device And TestFlight Preparation: partially complete.
  - Done: app icon, privacy strings/review notes, release checklist.
  - Not done: signing team setup, real-device QA, Archive build, TestFlight.
- Phase 5, Web Compatibility And Migration: mostly complete.
  - Done: web/iOS format comparison, adapter tests, migration note, direct iOS import for web JSON exports, pre-import confirmation summary dialog.
  - Not done: routine web deployment stability checks as the iOS work continues.

Current release blockers:

- The user confirmed on 2026-07-07 that they are not in front of the Mac, so Xcode Apple Account login and real iPhone connection cannot be done for now.
- Paid Apple Developer Program membership is not planned right now because of cost.
- Without a paid Apple Developer Program team, TestFlight/App Store distribution is blocked.
- Free Apple Account Personal Team signing should still be enough later for own-device testing from Xcode, but it requires the user to log into Xcode and connect an iPhone locally.

## Verification Snapshot

Commands run from the main repo on 2026-07-07:

```bash
npm test -- --run
```

Result: passed, 10 web test files and 43 tests.

```bash
jq empty \
  ios/FamilyMemories/FamilyMemories/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json \
  ios/FamilyMemories/FamilyMemories/Resources/Assets.xcassets/Contents.json \
  ios/FamilyMemories/FamilyMemories/Localization/Localizable.xcstrings
```

Result: passed.

```bash
plutil -lint \
  ios/FamilyMemories/FamilyMemories.xcodeproj/project.pbxproj \
  ios/FamilyMemories/FamilyMemories/App/Info.plist \
  ios/FamilyMemories/FamilyMemories/Resources/PrivacyInfo.xcprivacy
```

Result: passed.

```bash
xcodebuild \
  -project ios/FamilyMemories/FamilyMemories.xcodeproj \
  -scheme FamilyMemories \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  -derivedDataPath /Volumes/p310-1/DerivedData/FamilyMemories \
  -only-testing:FamilyMemoriesTests \
  test
```

Result: passed, 54 iOS unit tests.

```bash
xcodebuild -quiet \
  -project ios/FamilyMemories/FamilyMemories.xcodeproj \
  -scheme FamilyMemories \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  -derivedDataPath /Volumes/p310-1/DerivedData/FamilyMemories \
  -only-testing:FamilyMemoriesUITests \
  test
```

Result: passed, 5 UI tests.

Important note: the first UI test attempt failed because the Simulator service hub exited before the test runner connected. After this recovery, the same UI suite passed:

```bash
xcrun simctl shutdown 7FD29A7D-AA28-4BB9-91F7-C3A0FD014F50 >/dev/null 2>&1 || true
xcrun simctl erase 7FD29A7D-AA28-4BB9-91F7-C3A0FD014F50
```

Use that recovery only for the test simulator. It erases simulator app data.

## Resume Checklist

Start here:

```bash
cd /Volumes/p310/Codex/projects/family-memories
git status --short --branch
git log --oneline -10
```

Recommended quick verification:

```bash
npm test -- --run
git diff --check
jq empty \
  ios/FamilyMemories/FamilyMemories/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json \
  ios/FamilyMemories/FamilyMemories/Resources/Assets.xcassets/Contents.json \
  ios/FamilyMemories/FamilyMemories/Localization/Localizable.xcstrings
plutil -lint \
  ios/FamilyMemories/FamilyMemories.xcodeproj/project.pbxproj \
  ios/FamilyMemories/FamilyMemories/App/Info.plist \
  ios/FamilyMemories/FamilyMemories/Resources/PrivacyInfo.xcprivacy
```

Run iOS tests:

```bash
xcodebuild \
  -project ios/FamilyMemories/FamilyMemories.xcodeproj \
  -scheme FamilyMemories \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  -derivedDataPath /Volumes/p310-1/DerivedData/FamilyMemories \
  test
```

## Recommended Next Work

1. Keep web preview/deployment stable: run `npm run build`, check GitHub Pages assumptions, and avoid adding server storage.
2. When the user is back at the Mac, configure Xcode with a free Apple Account Personal Team and run the app on a personal iPhone.
3. After real-device testing, decide whether to stay with direct Xcode install for private use or pay for Apple Developer Program only when TestFlight/App Store distribution is truly needed.
4. Later enhancements to keep in backlog: pinch zoom, richer metadata, iCloud Drive opt-in backup/sync, hybrid photo storage, Android, desktop, and cross-platform strategy.

## Product Constraints To Preserve

- Do not add accounts, backend services, or automatic cloud sync to the initial version.
- Do not store user photos in GitHub. Photos stay in browser-local storage, iOS app-private storage, or user-exported backup files.
- UI language can switch between Chinese and English, but user-entered content must not be translated automatically.
- Keep destructive actions explicit and reversible through manual backups where practical.
- Keep backup/import compatibility tests close to any schema or storage changes.
