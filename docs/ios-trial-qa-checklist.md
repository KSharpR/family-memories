# iOS Trial QA Checklist

Use this checklist before handing the native iOS app to a small trial user group.

## Environment

- [ ] Open the main repository at `/Volumes/p310/Codex/projects/family-memories`.
- [ ] Confirm Xcode 26.5 is selected:

```bash
xcodebuild -version
xcode-select -p
```

- [ ] Confirm the iPhone 17 Pro simulator exists:

```bash
xcrun simctl list devices available | grep "iPhone 17 Pro"
```

- [ ] Run static checks:

```bash
jq empty ios/FamilyMemories/FamilyMemories/Localization/Localizable.xcstrings
plutil -lint ios/FamilyMemories/FamilyMemories.xcodeproj/project.pbxproj ios/FamilyMemories/FamilyMemories/App/Info.plist
git diff --check
```

- [ ] Run unit tests:

```bash
xcodebuild \
  -project ios/FamilyMemories/FamilyMemories.xcodeproj \
  -scheme FamilyMemories \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  -derivedDataPath /Volumes/p310-1/DerivedData/FamilyMemories \
  -only-testing:FamilyMemoriesTests \
  test
```

- [ ] Run UI smoke tests:

```bash
xcodebuild \
  -project ios/FamilyMemories/FamilyMemories.xcodeproj \
  -scheme FamilyMemories \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  -derivedDataPath /Volumes/p310-1/DerivedData/FamilyMemories \
  -only-testing:FamilyMemoriesUITests \
  test
```

## Simulator Recovery

If Simulator reports `Application failed preflight checks` or `Busy`, reset the target simulator and rerun the failed command:

```bash
xcrun simctl shutdown 7FD29A7D-AA28-4BB9-91F7-C3A0FD014F50 >/dev/null 2>&1 || true
xcrun simctl erase 7FD29A7D-AA28-4BB9-91F7-C3A0FD014F50
```

This clears only the simulator app data. It does not change project source files or real iPhone data.

## Simulator App Flow

- [ ] Launch the app on iPhone 17 Pro simulator.
- [ ] Confirm the empty timeline shows the import action.
- [ ] Switch to Settings.
- [ ] Confirm language can switch between Chinese and English.
- [ ] Confirm Settings shows backup controls, privacy copy, and local storage usage.
- [ ] Import one valid image.
- [ ] Confirm the import review sheet shows the ready-to-save section.
- [ ] Save the memory.
- [ ] Confirm the memory appears in Timeline.
- [ ] Open the memory detail screen.
- [ ] Edit story, people, and date.
- [ ] Confirm user-entered content keeps its original language and is not translated.
- [ ] Confirm the memory appears in Album.
- [ ] Open album preview.
- [ ] Filter Album by year.
- [ ] Filter Album by person.
- [ ] Enter batch selection mode.
- [ ] Select one memory.
- [ ] Cancel selection without deleting.

## Real iPhone Flow

- [ ] Install a debug or TestFlight build on a real iPhone.
- [ ] Import 5-10 real photos through the system photo picker.
- [ ] Include at least one photo with a known capture date.
- [ ] Confirm imported photos are copied into the app and remain visible after relaunch.
- [ ] Confirm the default memory date uses photo metadata when available.
- [ ] Edit story, people, and date on at least two memories.
- [ ] Confirm Timeline grouping remains correct after editing dates.
- [ ] Confirm Album filters work with real people tags.
- [ ] Confirm Settings storage usage increases after import.

## Backup Export And Import

- [ ] Create at least three saved memories.
- [ ] Export a `.familymemories` backup from Settings.
- [ ] Save the backup to Files or share it to a controlled location.
- [ ] Import the same backup.
- [ ] Confirm the app shows an import confirmation before restoring.
- [ ] Confirm the confirmation includes memory count and backup creation date.
- [ ] Confirm the merge and same-ID overwrite behavior is explained before import.
- [ ] Confirm import completes and memories are still available.
- [ ] Relaunch the app and confirm restored memories remain visible.

## Web JSON Migration

- [ ] Export a JSON album from the web app.
- [ ] Move the JSON file to the simulator or real iPhone through Files, AirDrop, or another user-controlled location.
- [ ] Open Settings in the iOS app.
- [ ] Tap Import web JSON / 导入 Web JSON.
- [ ] Select the exported `.json` file.
- [ ] Confirm a pre-import confirmation summary dialog appears.
- [ ] Confirm the dialog includes memory count.
- [ ] Confirm the dialog includes same-ID overwrite count when applicable.
- [ ] Confirm the dialog includes the date range of imported memories when applicable.
- [ ] Tap cancel; confirm no memories were imported and the local library is unchanged.
- [ ] Repeat the import and tap confirm.
- [ ] Confirm import completion feedback appears.
- [ ] Confirm imported memories appear in Timeline and Album.
- [ ] Confirm story text and people tags keep the user's original language.
- [ ] Export a new `.familymemories` backup from iOS after migration.

## Partial Import Failure

- [ ] Attempt an import batch with at least one valid image and one unsupported/corrupt file when possible.
- [ ] Confirm successfully imported photos are shown separately from failed imports.
- [ ] Confirm failed imports show filename and a readable reason.
- [ ] Save the successful photos.
- [ ] Confirm failed photos were not added to Timeline or Album.

## Destructive Actions

- [ ] Open a memory detail screen and delete one memory.
- [ ] Confirm the app shows a destructive confirmation first.
- [ ] Confirm the deleted memory disappears from Timeline and Album.
- [ ] In Album, enter batch selection mode.
- [ ] Select multiple memories.
- [ ] Tap delete.
- [ ] Confirm the app shows a destructive confirmation first.
- [ ] Confirm selected memories and their local image files are removed.
- [ ] Open Settings.
- [ ] Tap Clear local data / 清除本地数据.
- [ ] Confirm the app shows a destructive confirmation first.
- [ ] Cancel once and confirm existing memories remain.
- [ ] Repeat and confirm the reset.
- [ ] Confirm Timeline and Album return to the empty state.
- [ ] Confirm Settings storage usage returns to 0 bytes or the platform's empty app baseline.

## Privacy Checks

- [ ] Confirm the app does not ask for an account.
- [ ] Confirm the app does not ask for server or cloud credentials.
- [ ] Confirm the app uses the system photo picker instead of scanning the whole library.
- [ ] Confirm backups are only created after tapping export.
- [ ] Confirm imported user stories and people tags are never machine-translated when switching UI language.
