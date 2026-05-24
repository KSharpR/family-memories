# iOS Release Checklist

Use this checklist before creating a private TestFlight build.

## Build Identity

- [ ] Confirm the Apple Developer Team ID to use for signing.
- [ ] Decide whether the production bundle ID remains `com.ksharpr.FamilyMemories`.
- [ ] Set `DEVELOPMENT_TEAM` for the app target when signing is ready.
- [ ] Keep `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` aligned with the TestFlight build notes.
- [ ] Confirm Debug simulator builds still keep DerivedData on `/Volumes/p310-1/DerivedData/FamilyMemories`.

## Privacy Review

- [ ] Confirm the app still has no account, app-owned server, analytics SDK, ad SDK, or automatic upload.
- [ ] Confirm photo import still uses the system picker and only copies user-selected photos.
- [ ] Confirm `.familymemories` backups are created only after the user taps export.
- [ ] Confirm Settings explains local copies, backup control, and destructive reset behavior in Chinese and English.
- [ ] Keep `PrivacyInfo.xcprivacy` aligned with actual code paths:
  - `NSPrivacyAccessedAPICategoryUserDefaults` with reason `CA92.1` for app-only language preference storage.
  - `NSPrivacyAccessedAPICategoryFileTimestamp` with reason `C617.1` for file metadata inside the app container.
- [ ] App Store privacy answers should be reviewed as "Data Not Collected" only while no user data leaves the device or user-controlled backup destination.

## App Store Metadata Draft

- [ ] App name: `Family Memories`.
- [ ] Subtitle draft: `Private family album and memoirs`.
- [ ] Category: Lifestyle.
- [ ] Age rating: no user-generated public sharing, no accounts, no web content.
- [ ] Privacy policy: prepare a short hosted page before external TestFlight if Apple requires a URL.

## TestFlight Notes Draft

```text
Family Memories is a local-first private album app for importing selected family photos, adding stories, dates, and people tags, browsing timeline/album views, and exporting manual .familymemories backups.

Please test:
- Import 5-10 real photos through the system picker.
- Edit story, date, and people tags.
- Switch Chinese/English UI and confirm your own text is not translated.
- Export a backup, save it to Files, and import it again.
- Try the Settings local data reset only after exporting a backup.

Known limitations:
- No account, server sync, or shared collaboration.
- No iCloud Drive sync mode yet.
- No pinch-to-zoom image viewer yet.
```

## Archive Readiness

- [ ] Run `docs/ios-trial-qa-checklist.md`.
- [ ] Run unit tests for `FamilyMemoriesTests`.
- [ ] Run UI smoke tests for `FamilyMemoriesUITests`.
- [ ] Create an Archive build in Xcode after signing is configured.
- [ ] Generate and review Xcode's privacy report from the archive.
- [ ] Install the TestFlight build on at least one real iPhone and repeat backup export/import.
