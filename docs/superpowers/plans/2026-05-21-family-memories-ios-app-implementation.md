# Family Memories iOS App Implementation Plan

> **⚠ ARCHIVAL / HISTORICAL — This plan is complete. Do not follow its worktree or branch instructions below.**
>
> All iOS implementation work has been completed and merged into `main` at `/Volumes/p310/Codex/projects/family-memories`. The current baseline is commit `c9fa230 feat: confirm web json imports on ios`.
>
> **Do NOT create or use:**
> - Branch `ios/native-app`
> - Worktree `../family-memories-ios-app`
> - Worktree `.worktrees/ios-native-app`
>
> The worktree and branch instructions below are left in place as a historical record of how this plan was originally executed. Future agents should start from `main` in the repository root and follow `docs/project-status.md` for current state.

> **For agentic workers (historical):** This plan originally required subagent-driven-development or executing-plans to implement task-by-task. Since this plan is now complete, these instructions are preserved for reference only.

**Goal:** Build a native SwiftUI iOS first version that imports selected photos, stores them locally, enriches them with memoir metadata, browses them by timeline and album, and supports manual backup import/export without accounts or servers.

**Architecture:** Create a native iOS app under `ios/FamilyMemories` with SwiftUI views, observable view models, SwiftData metadata storage, and file-backed original/thumbnail storage in Application Support. Keep import, file storage, metadata, backup, and localization behind small service boundaries so the local data loop is testable before UI polish expands.

**Tech Stack:** SwiftUI, SwiftData, PhotosUI `PhotosPicker`, FileManager, ImageIO/UIKit image processing, ZIPFoundation for `.familymemories` backup archives, XCTest, XcodeBuildMCP or `xcodebuild` on an iOS simulator.

---

## Scope Check

The approved iOS design is one cohesive first native app milestone. It includes multiple screens, but each screen depends on the same local-first import, storage, metadata, and backup loop, so one implementation plan is appropriate. Server accounts, cloud sync, payments, collaboration, advanced photo editing, slideshow, and cross-platform clients remain outside this implementation plan.

## Execution Setup

Run implementation in an isolated worktree. The user already chose a worktree-based workflow, so create or reuse a local implementation worktree before changing app code.

```bash
cd /Volumes/p310/Codex/projects/family-memories
git status --short --branch
git worktree add ../family-memories-ios-app -b ios/native-app
cd ../family-memories-ios-app
```

If branch `ios/native-app` already exists, use:

```bash
cd /Volumes/p310/Codex/projects/family-memories
git worktree add ../family-memories-ios-app ios/native-app
cd ../family-memories-ios-app
```

Before the first simulator build or test, use XcodeBuildMCP if its tools are available in the current session. Call `session_show_defaults` first when exposed. If XcodeBuildMCP project defaults are unavailable, use the shell commands listed in each task.

## File Structure Map

```text
ios/FamilyMemories/FamilyMemories.xcodeproj
  Native iOS project generated from the iOS App SwiftUI template
ios/FamilyMemories/FamilyMemories/FamilyMemoriesApp.swift
  App entry and SwiftData model container wiring
ios/FamilyMemories/FamilyMemories/App/AppRootView.swift
  Root tab shell: Timeline, Album, Settings
ios/FamilyMemories/FamilyMemories/App/AppEnvironment.swift
  Runtime service dependencies
ios/FamilyMemories/FamilyMemories/Domain/FamilyMemory.swift
  App domain model used by UI and services
ios/FamilyMemories/FamilyMemories/Domain/MemoryDraft.swift
  Import/edit input model before persistence
ios/FamilyMemories/FamilyMemories/Domain/PeopleTagNormalizer.swift
  People tag trimming, empty removal, and exact deduplication
ios/FamilyMemories/FamilyMemories/Domain/TimelineGrouping.swift
  Year/month grouping rules for timeline and album ordering
ios/FamilyMemories/FamilyMemories/Persistence/MemoryRecord.swift
  SwiftData entity
ios/FamilyMemories/FamilyMemories/Persistence/MemoryRepository.swift
  Metadata persistence boundary
ios/FamilyMemories/FamilyMemories/Storage/MemoryFileStore.swift
  Application Support directories, original writes, thumbnail writes, delete cleanup
ios/FamilyMemories/FamilyMemories/Importing/PhotoImportService.swift
  PhotosPicker item loading, metadata extraction, file copy, thumbnail generation
ios/FamilyMemories/FamilyMemories/Importing/ImportedPhoto.swift
  Imported photo result and partial failure reporting
ios/FamilyMemories/FamilyMemories/Backup/BackupManifest.swift
  Backup manifest model and validation
ios/FamilyMemories/FamilyMemories/Backup/BackupMemoryDTO.swift
  JSON-compatible memory backup shape
ios/FamilyMemories/FamilyMemories/Backup/BackupPackageService.swift
  Export/import validation and archive assembly
ios/FamilyMemories/FamilyMemories/Localization/AppLanguage.swift
  Chinese/English language state
ios/FamilyMemories/FamilyMemories/Localization/Localizable.xcstrings
  Localized UI copy
ios/FamilyMemories/FamilyMemories/Features/Timeline/TimelineView.swift
  Default home timeline
ios/FamilyMemories/FamilyMemories/Features/Timeline/TimelineViewModel.swift
  Timeline loading, grouping, import entry state
ios/FamilyMemories/FamilyMemories/Features/MemoryDetail/MemoryDetailView.swift
  Read and edit one memory
ios/FamilyMemories/FamilyMemories/Features/ImportReview/ImportReviewView.swift
  Batch import review and metadata completion
ios/FamilyMemories/FamilyMemories/Features/Album/AlbumReaderView.swift
  Secondary memoir reading view
ios/FamilyMemories/FamilyMemories/Features/Settings/SettingsView.swift
  Language, privacy copy, backup import/export
ios/FamilyMemories/FamilyMemories/Resources/FamilyMemoriesUTTypes.swift
  `.familymemories` document type constants
ios/FamilyMemories/FamilyMemoriesTests/DomainTests.swift
  Domain model, tag normalization, timeline grouping tests
ios/FamilyMemories/FamilyMemoriesTests/MemoryFileStoreTests.swift
  File storage tests with temporary directories
ios/FamilyMemories/FamilyMemoriesTests/MemoryRepositoryTests.swift
  SwiftData repository tests with in-memory model container
ios/FamilyMemories/FamilyMemoriesTests/PhotoImportServiceTests.swift
  Import service tests with fake picker data
ios/FamilyMemories/FamilyMemoriesTests/BackupPackageServiceTests.swift
  Backup validation, export, append import tests
ios/FamilyMemories/FamilyMemoriesUITests/FamilyMemoriesUITests.swift
  Empty state, language switch, timeline, album, and settings smoke tests
README.md
  Add iOS development, build, and privacy notes
```

## Task 1: Isolated Worktree And iOS Project Scaffold

**Files:**
- Create: `ios/FamilyMemories/FamilyMemories.xcodeproj`
- Create: `ios/FamilyMemories/FamilyMemories/FamilyMemoriesApp.swift`
- Create: `ios/FamilyMemories/FamilyMemories/App/AppRootView.swift`
- Create: `ios/FamilyMemories/FamilyMemoriesTests/FamilyMemoriesTests.swift`
- Create: `ios/FamilyMemories/FamilyMemoriesUITests/FamilyMemoriesUITests.swift`
- Modify: `.gitignore`

- [ ] **Step 1: Create or enter the isolated worktree**

Run:

```bash
cd /Volumes/p310/Codex/projects/family-memories
git status --short --branch
git worktree list
```

Expected: the current repository is visible and no uncommitted user changes are overwritten.

Create the iOS implementation worktree when it is missing:

```bash
git worktree add ../family-memories-ios-app -b ios/native-app
cd ../family-memories-ios-app
```

If the branch exists:

```bash
git worktree add ../family-memories-ios-app ios/native-app
cd ../family-memories-ios-app
```

- [ ] **Step 2: Create the Xcode project**

Create a new Xcode iOS App project with these exact settings:

```text
Product Name: FamilyMemories
Team: None
Organization Identifier: com.ksharpr
Bundle Identifier: com.ksharpr.FamilyMemories
Interface: SwiftUI
Language: Swift
Storage: None
Include Tests: Yes
Minimum Deployments: iOS 17.0
Project location: ios/FamilyMemories
```

If an XcodeBuildMCP project scaffolding tool is available, use it with the same settings. Otherwise use Xcode's iOS App template and save the generated project under `ios/FamilyMemories`.

Expected generated files:

```text
ios/FamilyMemories/FamilyMemories.xcodeproj
ios/FamilyMemories/FamilyMemories/FamilyMemoriesApp.swift
ios/FamilyMemories/FamilyMemories/ContentView.swift
ios/FamilyMemories/FamilyMemoriesTests/FamilyMemoriesTests.swift
ios/FamilyMemories/FamilyMemoriesUITests/FamilyMemoriesUITests.swift
```

- [ ] **Step 3: Replace the generated content view with the root shell**

Rename `ios/FamilyMemories/FamilyMemories/ContentView.swift` to `ios/FamilyMemories/FamilyMemories/App/AppRootView.swift` and set its content to:

```swift
import SwiftUI

struct AppRootView: View {
    var body: some View {
        TabView {
            NavigationStack {
                Text("timeline.empty.title")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .tabItem {
                Label("tab.timeline", systemImage: "clock")
            }

            NavigationStack {
                Text("album.empty.title")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .tabItem {
                Label("tab.album", systemImage: "book.pages")
            }

            NavigationStack {
                Text("settings.title")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .tabItem {
                Label("tab.settings", systemImage: "gearshape")
            }
        }
    }
}

#Preview {
    AppRootView()
}
```

Replace `ios/FamilyMemories/FamilyMemories/FamilyMemoriesApp.swift` with:

```swift
import SwiftUI

@main
struct FamilyMemoriesApp: App {
    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
    }
}
```

- [ ] **Step 4: Add a scaffold smoke test**

Replace `ios/FamilyMemories/FamilyMemoriesTests/FamilyMemoriesTests.swift` with:

```swift
import XCTest
@testable import FamilyMemories

final class FamilyMemoriesTests: XCTestCase {
    func testAppRootViewCanBeConstructed() {
        _ = AppRootView()
    }
}
```

- [ ] **Step 5: Run the initial build and tests**

With XcodeBuildMCP, set or confirm defaults for:

```text
Project: ios/FamilyMemories/FamilyMemories.xcodeproj
Scheme: FamilyMemories
Simulator: any available iPhone simulator running iOS 17 or newer
```

Then run the simulator test tool.

Shell fallback:

```bash
xcodebuild \
  -project ios/FamilyMemories/FamilyMemories.xcodeproj \
  -scheme FamilyMemories \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  test
```

Expected: build succeeds and `testAppRootViewCanBeConstructed` passes.

- [ ] **Step 6: Commit the scaffold**

```bash
git add ios/FamilyMemories .gitignore
git commit -m "feat: scaffold native ios app"
```

## Task 2: Domain Model, People Tags, And Timeline Grouping

**Files:**
- Create: `ios/FamilyMemories/FamilyMemories/Domain/FamilyMemory.swift`
- Create: `ios/FamilyMemories/FamilyMemories/Domain/MemoryDraft.swift`
- Create: `ios/FamilyMemories/FamilyMemories/Domain/PeopleTagNormalizer.swift`
- Create: `ios/FamilyMemories/FamilyMemories/Domain/TimelineGrouping.swift`
- Modify: `ios/FamilyMemories/FamilyMemoriesTests/DomainTests.swift`

- [ ] **Step 1: Write failing domain tests**

Create `ios/FamilyMemories/FamilyMemoriesTests/DomainTests.swift`:

```swift
import XCTest
@testable import FamilyMemories

final class DomainTests: XCTestCase {
    func testPeopleTagsAreTrimmedAndDeduplicated() {
        let normalized = PeopleTagNormalizer.normalize([
            " Mom ",
            "",
            "Dad",
            "Mom",
            "  ",
            "外婆"
        ])

        XCTAssertEqual(normalized, ["Mom", "Dad", "外婆"])
    }

    func testMemoryDraftUsesSourceDateUntilUserOverridesDate() {
        let sourceDate = Date(timeIntervalSince1970: 1_700_000_000)
        let manualDate = Date(timeIntervalSince1970: 1_710_000_000)

        var draft = MemoryDraft(
            originalFilename: "family.jpg",
            originalPath: "Originals/family.jpg",
            thumbnailPath: "Thumbnails/family.jpg",
            sourceCreatedAt: sourceDate
        )

        XCTAssertEqual(draft.date, sourceDate)

        draft.date = manualDate
        XCTAssertEqual(draft.date, manualDate)
        XCTAssertEqual(draft.sourceCreatedAt, sourceDate)
    }

    func testTimelineGroupingOrdersYearsAndMonthsDescending() {
        let calendar = Calendar(identifier: .gregorian)
        let memories = [
            FamilyMemory.fixture(id: "old", date: calendar.date(from: DateComponents(year: 2022, month: 7, day: 2))!),
            FamilyMemory.fixture(id: "newer", date: calendar.date(from: DateComponents(year: 2024, month: 3, day: 4))!),
            FamilyMemory.fixture(id: "sameMonth", date: calendar.date(from: DateComponents(year: 2024, month: 3, day: 1))!)
        ]

        let sections = TimelineGrouping.sections(for: memories, calendar: calendar)

        XCTAssertEqual(sections.map(\.id), ["2024-03", "2022-07"])
        XCTAssertEqual(sections[0].memories.map(\.id), ["newer", "sameMonth"])
    }
}

private extension FamilyMemory {
    static func fixture(id: String, date: Date) -> FamilyMemory {
        FamilyMemory(
            id: id,
            originalFilename: "\(id).jpg",
            originalPath: "Originals/\(id).jpg",
            thumbnailPath: "Thumbnails/\(id).jpg",
            story: "",
            date: date,
            people: [],
            filter: "original",
            createdAt: date,
            updatedAt: date,
            sourceCreatedAt: date,
            sourceAssetIdentifier: nil
        )
    }
}
```

- [ ] **Step 2: Run tests and verify failure**

Run:

```bash
xcodebuild \
  -project ios/FamilyMemories/FamilyMemories.xcodeproj \
  -scheme FamilyMemories \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:FamilyMemoriesTests/DomainTests \
  test
```

Expected: tests fail because `FamilyMemory`, `MemoryDraft`, `PeopleTagNormalizer`, and `TimelineGrouping` do not exist.

- [ ] **Step 3: Add the domain model**

Create `ios/FamilyMemories/FamilyMemories/Domain/FamilyMemory.swift`:

```swift
import Foundation

struct FamilyMemory: Identifiable, Equatable, Hashable {
    let id: String
    var originalFilename: String
    var originalPath: String
    var thumbnailPath: String
    var story: String
    var date: Date
    var people: [String]
    var filter: String
    var createdAt: Date
    var updatedAt: Date
    var sourceCreatedAt: Date?
    var sourceAssetIdentifier: String?
}
```

Create `ios/FamilyMemories/FamilyMemories/Domain/MemoryDraft.swift`:

```swift
import Foundation

struct MemoryDraft: Equatable, Identifiable {
    let id: String
    var originalFilename: String
    var originalPath: String
    var thumbnailPath: String
    var story: String
    var date: Date
    var people: [String]
    var filter: String
    var sourceCreatedAt: Date?
    var sourceAssetIdentifier: String?

    init(
        id: String = UUID().uuidString,
        originalFilename: String,
        originalPath: String,
        thumbnailPath: String,
        story: String = "",
        date: Date? = nil,
        people: [String] = [],
        filter: String = "original",
        sourceCreatedAt: Date? = nil,
        sourceAssetIdentifier: String? = nil
    ) {
        self.id = id
        self.originalFilename = originalFilename
        self.originalPath = originalPath
        self.thumbnailPath = thumbnailPath
        self.story = story
        self.date = date ?? sourceCreatedAt ?? Date()
        self.people = PeopleTagNormalizer.normalize(people)
        self.filter = filter
        self.sourceCreatedAt = sourceCreatedAt
        self.sourceAssetIdentifier = sourceAssetIdentifier
    }

    func persisted(now: Date = Date()) -> FamilyMemory {
        FamilyMemory(
            id: id,
            originalFilename: originalFilename,
            originalPath: originalPath,
            thumbnailPath: thumbnailPath,
            story: story,
            date: date,
            people: PeopleTagNormalizer.normalize(people),
            filter: filter,
            createdAt: now,
            updatedAt: now,
            sourceCreatedAt: sourceCreatedAt,
            sourceAssetIdentifier: sourceAssetIdentifier
        )
    }
}
```

Create `ios/FamilyMemories/FamilyMemories/Domain/PeopleTagNormalizer.swift`:

```swift
import Foundation

enum PeopleTagNormalizer {
    static func normalize(_ rawTags: [String]) -> [String] {
        var seen = Set<String>()
        var normalized: [String] = []

        for tag in rawTags {
            let trimmed = tag.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed.isEmpty == false else { continue }
            guard seen.contains(trimmed) == false else { continue }
            seen.insert(trimmed)
            normalized.append(trimmed)
        }

        return normalized
    }
}
```

Create `ios/FamilyMemories/FamilyMemories/Domain/TimelineGrouping.swift`:

```swift
import Foundation

struct TimelineSection: Identifiable, Equatable {
    let id: String
    let year: Int
    let month: Int
    let memories: [FamilyMemory]
}

enum TimelineGrouping {
    static func sections(
        for memories: [FamilyMemory],
        calendar: Calendar = .current
    ) -> [TimelineSection] {
        let grouped = Dictionary(grouping: memories) { memory in
            let components = calendar.dateComponents([.year, .month], from: memory.date)
            return YearMonth(year: components.year ?? 1, month: components.month ?? 1)
        }

        return grouped
            .map { key, values in
                TimelineSection(
                    id: String(format: "%04d-%02d", key.year, key.month),
                    year: key.year,
                    month: key.month,
                    memories: values.sorted { $0.date > $1.date }
                )
            }
            .sorted {
                if $0.year != $1.year { return $0.year > $1.year }
                return $0.month > $1.month
            }
    }
}

private struct YearMonth: Hashable {
    let year: Int
    let month: Int
}
```

- [ ] **Step 4: Run domain tests**

Run:

```bash
xcodebuild \
  -project ios/FamilyMemories/FamilyMemories.xcodeproj \
  -scheme FamilyMemories \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:FamilyMemoriesTests/DomainTests \
  test
```

Expected: all `DomainTests` pass.

- [ ] **Step 5: Commit domain layer**

```bash
git add ios/FamilyMemories/FamilyMemories/Domain ios/FamilyMemories/FamilyMemoriesTests/DomainTests.swift
git commit -m "feat: add ios memory domain model"
```

## Task 3: Private File Storage For Originals And Thumbnails

**Files:**
- Create: `ios/FamilyMemories/FamilyMemories/Storage/MemoryFileStore.swift`
- Create: `ios/FamilyMemories/FamilyMemoriesTests/MemoryFileStoreTests.swift`

- [ ] **Step 1: Write failing file store tests**

Create `ios/FamilyMemories/FamilyMemoriesTests/MemoryFileStoreTests.swift`:

```swift
import XCTest
@testable import FamilyMemories

final class MemoryFileStoreTests: XCTestCase {
    private var rootURL: URL!
    private var store: MemoryFileStore!

    override func setUpWithError() throws {
        rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        store = try MemoryFileStore(rootURL: rootURL)
    }

    override func tearDownWithError() throws {
        if let rootURL {
            try? FileManager.default.removeItem(at: rootURL)
        }
    }

    func testCreatesExpectedDirectories() throws {
        XCTAssertTrue(FileManager.default.fileExists(atPath: store.originalsDirectory.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: store.thumbnailsDirectory.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: store.backupsDirectory.path))
    }

    func testWritesOriginalAndThumbnailUsingStableMemoryId() throws {
        let original = Data([1, 2, 3])
        let thumbnail = Data([4, 5, 6])

        let paths = try store.writeImageFiles(
            memoryID: "abc",
            originalFilename: "photo.JPG",
            originalData: original,
            thumbnailData: thumbnail
        )

        XCTAssertEqual(paths.originalRelativePath, "Originals/abc.jpg")
        XCTAssertEqual(paths.thumbnailRelativePath, "Thumbnails/abc.jpg")
        XCTAssertEqual(try Data(contentsOf: store.url(forRelativePath: paths.originalRelativePath)), original)
        XCTAssertEqual(try Data(contentsOf: store.url(forRelativePath: paths.thumbnailRelativePath)), thumbnail)
    }

    func testDeleteMemoryFilesRemovesOriginalAndThumbnail() throws {
        let paths = try store.writeImageFiles(
            memoryID: "gone",
            originalFilename: "gone.png",
            originalData: Data([9]),
            thumbnailData: Data([8])
        )

        try store.deleteMemoryFiles(
            originalRelativePath: paths.originalRelativePath,
            thumbnailRelativePath: paths.thumbnailRelativePath
        )

        XCTAssertFalse(FileManager.default.fileExists(atPath: store.url(forRelativePath: paths.originalRelativePath).path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: store.url(forRelativePath: paths.thumbnailRelativePath).path))
    }
}
```

- [ ] **Step 2: Run tests and verify failure**

Run:

```bash
xcodebuild \
  -project ios/FamilyMemories/FamilyMemories.xcodeproj \
  -scheme FamilyMemories \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:FamilyMemoriesTests/MemoryFileStoreTests \
  test
```

Expected: tests fail because `MemoryFileStore` does not exist.

- [ ] **Step 3: Implement the file store**

Create `ios/FamilyMemories/FamilyMemories/Storage/MemoryFileStore.swift`:

```swift
import Foundation

struct StoredImagePaths: Equatable {
    let originalRelativePath: String
    let thumbnailRelativePath: String
}

enum MemoryFileStoreError: Error, Equatable {
    case invalidRelativePath(String)
}

final class MemoryFileStore {
    let rootURL: URL
    let originalsDirectory: URL
    let thumbnailsDirectory: URL
    let backupsDirectory: URL

    init(rootURL: URL? = nil, fileManager: FileManager = .default) throws {
        let resolvedRoot: URL
        if let rootURL {
            resolvedRoot = rootURL
        } else {
            resolvedRoot = try fileManager
                .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("FamilyMemories", isDirectory: true)
        }

        self.rootURL = resolvedRoot
        self.originalsDirectory = resolvedRoot.appendingPathComponent("Originals", isDirectory: true)
        self.thumbnailsDirectory = resolvedRoot.appendingPathComponent("Thumbnails", isDirectory: true)
        self.backupsDirectory = resolvedRoot.appendingPathComponent("Backups", isDirectory: true)

        try fileManager.createDirectory(at: originalsDirectory, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: thumbnailsDirectory, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: backupsDirectory, withIntermediateDirectories: true)
    }

    func writeImageFiles(
        memoryID: String,
        originalFilename: String,
        originalData: Data,
        thumbnailData: Data
    ) throws -> StoredImagePaths {
        let fileExtension = normalizedExtension(from: originalFilename)
        let originalRelativePath = "Originals/\(memoryID).\(fileExtension)"
        let thumbnailRelativePath = "Thumbnails/\(memoryID).jpg"

        try originalData.write(to: url(forRelativePath: originalRelativePath), options: .atomic)
        try thumbnailData.write(to: url(forRelativePath: thumbnailRelativePath), options: .atomic)

        return StoredImagePaths(
            originalRelativePath: originalRelativePath,
            thumbnailRelativePath: thumbnailRelativePath
        )
    }

    func url(forRelativePath relativePath: String) -> URL {
        rootURL.appendingPathComponent(relativePath, isDirectory: false)
    }

    func deleteMemoryFiles(originalRelativePath: String, thumbnailRelativePath: String) throws {
        for path in [originalRelativePath, thumbnailRelativePath] {
            guard path.contains("..") == false, path.hasPrefix("/") == false else {
                throw MemoryFileStoreError.invalidRelativePath(path)
            }

            let url = url(forRelativePath: path)
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
            }
        }
    }

    private func normalizedExtension(from filename: String) -> String {
        let ext = URL(fileURLWithPath: filename).pathExtension.lowercased()
        if ["jpg", "jpeg", "png", "heic", "heif"].contains(ext) {
            return ext == "jpeg" ? "jpg" : ext
        }
        return "jpg"
    }
}
```

- [ ] **Step 4: Run file store tests**

Run:

```bash
xcodebuild \
  -project ios/FamilyMemories/FamilyMemories.xcodeproj \
  -scheme FamilyMemories \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:FamilyMemoriesTests/MemoryFileStoreTests \
  test
```

Expected: all `MemoryFileStoreTests` pass.

- [ ] **Step 5: Commit file storage**

```bash
git add ios/FamilyMemories/FamilyMemories/Storage ios/FamilyMemories/FamilyMemoriesTests/MemoryFileStoreTests.swift
git commit -m "feat: store imported photos locally"
```

## Task 4: SwiftData Metadata Repository

**Files:**
- Create: `ios/FamilyMemories/FamilyMemories/Persistence/MemoryRecord.swift`
- Create: `ios/FamilyMemories/FamilyMemories/Persistence/MemoryRepository.swift`
- Create: `ios/FamilyMemories/FamilyMemoriesTests/MemoryRepositoryTests.swift`
- Modify: `ios/FamilyMemories/FamilyMemories/FamilyMemoriesApp.swift`

- [ ] **Step 1: Write failing repository tests**

Create `ios/FamilyMemories/FamilyMemoriesTests/MemoryRepositoryTests.swift`:

```swift
import SwiftData
import XCTest
@testable import FamilyMemories

@MainActor
final class MemoryRepositoryTests: XCTestCase {
    private var container: ModelContainer!
    private var repository: MemoryRepository!

    override func setUpWithError() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: MemoryRecord.self, configurations: configuration)
        repository = MemoryRepository(context: container.mainContext)
    }

    func testSavesAndFetchesMemoriesDescendingByDate() throws {
        let older = FamilyMemory.fixture(id: "older", date: Date(timeIntervalSince1970: 100))
        let newer = FamilyMemory.fixture(id: "newer", date: Date(timeIntervalSince1970: 200))

        try repository.save(older)
        try repository.save(newer)

        XCTAssertEqual(try repository.fetchAll().map(\.id), ["newer", "older"])
    }

    func testUpdatesStoryPeopleAndDate() throws {
        var memory = FamilyMemory.fixture(id: "edit", date: Date(timeIntervalSince1970: 100))
        try repository.save(memory)

        memory.story = "A quiet afternoon"
        memory.people = ["Mom", "Dad"]
        memory.date = Date(timeIntervalSince1970: 300)
        try repository.save(memory)

        let saved = try XCTUnwrap(repository.fetch(id: "edit"))
        XCTAssertEqual(saved.story, "A quiet afternoon")
        XCTAssertEqual(saved.people, ["Mom", "Dad"])
        XCTAssertEqual(saved.date, Date(timeIntervalSince1970: 300))
    }

    func testDeletesMemoryRecord() throws {
        try repository.save(FamilyMemory.fixture(id: "delete", date: Date()))
        try repository.delete(id: "delete")

        XCTAssertNil(try repository.fetch(id: "delete"))
    }
}

private extension FamilyMemory {
    static func fixture(id: String, date: Date) -> FamilyMemory {
        FamilyMemory(
            id: id,
            originalFilename: "\(id).jpg",
            originalPath: "Originals/\(id).jpg",
            thumbnailPath: "Thumbnails/\(id).jpg",
            story: "",
            date: date,
            people: [],
            filter: "original",
            createdAt: date,
            updatedAt: date,
            sourceCreatedAt: date,
            sourceAssetIdentifier: nil
        )
    }
}
```

- [ ] **Step 2: Run tests and verify failure**

Run:

```bash
xcodebuild \
  -project ios/FamilyMemories/FamilyMemories.xcodeproj \
  -scheme FamilyMemories \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:FamilyMemoriesTests/MemoryRepositoryTests \
  test
```

Expected: tests fail because SwiftData persistence files do not exist.

- [ ] **Step 3: Add SwiftData record and repository**

Create `ios/FamilyMemories/FamilyMemories/Persistence/MemoryRecord.swift`:

```swift
import Foundation
import SwiftData

@Model
final class MemoryRecord {
    @Attribute(.unique) var id: String
    var originalFilename: String
    var originalPath: String
    var thumbnailPath: String
    var story: String
    var date: Date
    var people: [String]
    var filter: String
    var createdAt: Date
    var updatedAt: Date
    var sourceCreatedAt: Date?
    var sourceAssetIdentifier: String?

    init(memory: FamilyMemory) {
        self.id = memory.id
        self.originalFilename = memory.originalFilename
        self.originalPath = memory.originalPath
        self.thumbnailPath = memory.thumbnailPath
        self.story = memory.story
        self.date = memory.date
        self.people = memory.people
        self.filter = memory.filter
        self.createdAt = memory.createdAt
        self.updatedAt = memory.updatedAt
        self.sourceCreatedAt = memory.sourceCreatedAt
        self.sourceAssetIdentifier = memory.sourceAssetIdentifier
    }

    func apply(_ memory: FamilyMemory) {
        originalFilename = memory.originalFilename
        originalPath = memory.originalPath
        thumbnailPath = memory.thumbnailPath
        story = memory.story
        date = memory.date
        people = PeopleTagNormalizer.normalize(memory.people)
        filter = memory.filter
        createdAt = memory.createdAt
        updatedAt = Date()
        sourceCreatedAt = memory.sourceCreatedAt
        sourceAssetIdentifier = memory.sourceAssetIdentifier
    }

    var domain: FamilyMemory {
        FamilyMemory(
            id: id,
            originalFilename: originalFilename,
            originalPath: originalPath,
            thumbnailPath: thumbnailPath,
            story: story,
            date: date,
            people: people,
            filter: filter,
            createdAt: createdAt,
            updatedAt: updatedAt,
            sourceCreatedAt: sourceCreatedAt,
            sourceAssetIdentifier: sourceAssetIdentifier
        )
    }
}
```

Create `ios/FamilyMemories/FamilyMemories/Persistence/MemoryRepository.swift`:

```swift
import Foundation
import SwiftData

@MainActor
final class MemoryRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll() throws -> [FamilyMemory] {
        let descriptor = FetchDescriptor<MemoryRecord>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try context.fetch(descriptor).map(\.domain)
    }

    func fetch(id: String) throws -> FamilyMemory? {
        let descriptor = FetchDescriptor<MemoryRecord>(
            predicate: #Predicate { $0.id == id }
        )
        return try context.fetch(descriptor).first?.domain
    }

    func save(_ memory: FamilyMemory) throws {
        let descriptor = FetchDescriptor<MemoryRecord>(
            predicate: #Predicate { $0.id == memory.id }
        )

        if let existing = try context.fetch(descriptor).first {
            existing.apply(memory)
        } else {
            context.insert(MemoryRecord(memory: memory))
        }

        try context.save()
    }

    func delete(id: String) throws {
        let descriptor = FetchDescriptor<MemoryRecord>(
            predicate: #Predicate { $0.id == id }
        )

        for record in try context.fetch(descriptor) {
            context.delete(record)
        }

        try context.save()
    }
}
```

- [ ] **Step 4: Wire SwiftData model container into the app**

Replace `ios/FamilyMemories/FamilyMemories/FamilyMemoriesApp.swift` with:

```swift
import SwiftData
import SwiftUI

@main
struct FamilyMemoriesApp: App {
    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
        .modelContainer(for: MemoryRecord.self)
    }
}
```

- [ ] **Step 5: Run repository tests**

Run:

```bash
xcodebuild \
  -project ios/FamilyMemories/FamilyMemories.xcodeproj \
  -scheme FamilyMemories \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:FamilyMemoriesTests/MemoryRepositoryTests \
  test
```

Expected: all `MemoryRepositoryTests` pass.

- [ ] **Step 6: Commit metadata persistence**

```bash
git add ios/FamilyMemories/FamilyMemories/Persistence ios/FamilyMemories/FamilyMemories/FamilyMemoriesApp.swift ios/FamilyMemories/FamilyMemoriesTests/MemoryRepositoryTests.swift
git commit -m "feat: persist memory metadata with swiftdata"
```

## Task 5: Photo Import Service And Thumbnail Generation

**Files:**
- Create: `ios/FamilyMemories/FamilyMemories/Importing/ImportedPhoto.swift`
- Create: `ios/FamilyMemories/FamilyMemories/Importing/PhotoImportService.swift`
- Create: `ios/FamilyMemories/FamilyMemoriesTests/PhotoImportServiceTests.swift`

- [ ] **Step 1: Write failing import tests**

Create `ios/FamilyMemories/FamilyMemoriesTests/PhotoImportServiceTests.swift`:

```swift
import XCTest
@testable import FamilyMemories

final class PhotoImportServiceTests: XCTestCase {
    private var rootURL: URL!
    private var store: MemoryFileStore!

    override func setUpWithError() throws {
        rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        store = try MemoryFileStore(rootURL: rootURL)
    }

    override func tearDownWithError() throws {
        if let rootURL {
            try? FileManager.default.removeItem(at: rootURL)
        }
    }

    func testImportsValidImageIntoDraft() throws {
        let service = PhotoImportService(fileStore: store)
        let result = try service.importPhoto(
            PickedPhotoData(
                filename: "memory.jpg",
                imageData: Self.onePixelJPEG(),
                sourceCreatedAt: Date(timeIntervalSince1970: 100),
                sourceAssetIdentifier: "asset-1"
            )
        )

        XCTAssertEqual(result.failures, [])
        let draft = try XCTUnwrap(result.drafts.first)
        XCTAssertEqual(draft.originalFilename, "memory.jpg")
        XCTAssertEqual(draft.date, Date(timeIntervalSince1970: 100))
        XCTAssertEqual(draft.sourceAssetIdentifier, "asset-1")
        XCTAssertTrue(FileManager.default.fileExists(atPath: store.url(forRelativePath: draft.originalPath).path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: store.url(forRelativePath: draft.thumbnailPath).path))
    }

    func testReportsInvalidImageFailureWithoutThrowingBatchAway() throws {
        let service = PhotoImportService(fileStore: store)
        let result = try service.importPhotos([
            PickedPhotoData(filename: "bad.txt", imageData: Data([0]), sourceCreatedAt: nil, sourceAssetIdentifier: nil),
            PickedPhotoData(filename: "good.jpg", imageData: Self.onePixelJPEG(), sourceCreatedAt: nil, sourceAssetIdentifier: nil)
        ])

        XCTAssertEqual(result.drafts.count, 1)
        XCTAssertEqual(result.failures.count, 1)
        XCTAssertEqual(result.failures.first?.filename, "bad.txt")
    }

    private static func onePixelJPEG() -> Data {
        Data(base64Encoded: "/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAP//////////////////////////////////////////////////////////////////////////////////////2wBDAf//////////////////////////////////////////////////////////////////////////////////////wAARCAABAAEDASIAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAX/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/9oADAMBAAIQAxAAAAH/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/9oACAEBAAEFAqf/xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oACAEDAQE/ASP/xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oACAECAQE/ASP/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/9oACAEBAAY/Al//xAAUEAEAAAAAAAAAAAAAAAAAAAAA/9oACAEBAAE/IV//2gAMAwEAAgADAAAAEP/EFBQRAQAAAAAAAAAAAAAAAAAAABD/2gAIAQMBAT8QH//EFBQRAQAAAAAAAAAAAAAAAAAAABD/2gAIAQIBAT8QH//EFBABAQAAAAAAAAAAAAAAAAAAABD/2gAIAQEAAT8QH//Z")!
    }
}
```

- [ ] **Step 2: Run tests and verify failure**

Run:

```bash
xcodebuild \
  -project ios/FamilyMemories/FamilyMemories.xcodeproj \
  -scheme FamilyMemories \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:FamilyMemoriesTests/PhotoImportServiceTests \
  test
```

Expected: tests fail because import service files do not exist.

- [ ] **Step 3: Add import result models**

Create `ios/FamilyMemories/FamilyMemories/Importing/ImportedPhoto.swift`:

```swift
import Foundation

struct PickedPhotoData: Equatable {
    let filename: String
    let imageData: Data
    let sourceCreatedAt: Date?
    let sourceAssetIdentifier: String?
}

struct ImportFailure: Equatable {
    let filename: String
    let reason: String
}

struct PhotoImportResult: Equatable {
    var drafts: [MemoryDraft]
    var failures: [ImportFailure]
}
```

- [ ] **Step 4: Implement import service and thumbnail generation**

Create `ios/FamilyMemories/FamilyMemories/Importing/PhotoImportService.swift`:

```swift
import Foundation
import ImageIO
import UIKit

final class PhotoImportService {
    private let fileStore: MemoryFileStore

    init(fileStore: MemoryFileStore) {
        self.fileStore = fileStore
    }

    func importPhoto(_ pickedPhoto: PickedPhotoData) throws -> PhotoImportResult {
        try importPhotos([pickedPhoto])
    }

    func importPhotos(_ pickedPhotos: [PickedPhotoData]) throws -> PhotoImportResult {
        var drafts: [MemoryDraft] = []
        var failures: [ImportFailure] = []

        for pickedPhoto in pickedPhotos {
            guard UIImage(data: pickedPhoto.imageData) != nil else {
                failures.append(ImportFailure(filename: pickedPhoto.filename, reason: "Invalid image data"))
                continue
            }

            let memoryID = UUID().uuidString
            let thumbnailData = try makeThumbnailJPEGData(from: pickedPhoto.imageData)
            let paths = try fileStore.writeImageFiles(
                memoryID: memoryID,
                originalFilename: pickedPhoto.filename,
                originalData: pickedPhoto.imageData,
                thumbnailData: thumbnailData
            )

            drafts.append(
                MemoryDraft(
                    id: memoryID,
                    originalFilename: pickedPhoto.filename,
                    originalPath: paths.originalRelativePath,
                    thumbnailPath: paths.thumbnailRelativePath,
                    sourceCreatedAt: pickedPhoto.sourceCreatedAt,
                    sourceAssetIdentifier: pickedPhoto.sourceAssetIdentifier
                )
            )
        }

        return PhotoImportResult(drafts: drafts, failures: failures)
    }

    private func makeThumbnailJPEGData(from data: Data) throws -> Data {
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: 420,
            kCGImageSourceCreateThumbnailWithTransform: true
        ]

        guard
            let source = CGImageSourceCreateWithData(data as CFData, nil),
            let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }

        let image = UIImage(cgImage: thumbnail)
        guard let jpegData = image.jpegData(compressionQuality: 0.82) else {
            throw CocoaError(.fileWriteUnknown)
        }
        return jpegData
    }
}
```

- [ ] **Step 5: Run import tests**

Run:

```bash
xcodebuild \
  -project ios/FamilyMemories/FamilyMemories.xcodeproj \
  -scheme FamilyMemories \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:FamilyMemoriesTests/PhotoImportServiceTests \
  test
```

Expected: all `PhotoImportServiceTests` pass.

- [ ] **Step 6: Commit import service**

```bash
git add ios/FamilyMemories/FamilyMemories/Importing ios/FamilyMemories/FamilyMemoriesTests/PhotoImportServiceTests.swift
git commit -m "feat: import selected photos into local storage"
```

## Task 6: Timeline View Model And App Environment

**Files:**
- Create: `ios/FamilyMemories/FamilyMemories/App/AppEnvironment.swift`
- Create: `ios/FamilyMemories/FamilyMemories/Features/Timeline/TimelineViewModel.swift`
- Create: `ios/FamilyMemories/FamilyMemoriesTests/TimelineViewModelTests.swift`
- Modify: `ios/FamilyMemories/FamilyMemories/App/AppRootView.swift`

- [ ] **Step 1: Write failing timeline view model tests**

Create `ios/FamilyMemories/FamilyMemoriesTests/TimelineViewModelTests.swift`:

```swift
import XCTest
@testable import FamilyMemories

@MainActor
final class TimelineViewModelTests: XCTestCase {
    func testLoadsTimelineSectionsFromRepository() async throws {
        let repository = InMemoryMemoryRepository(memories: [
            .fixture(id: "one", date: Date(timeIntervalSince1970: 100)),
            .fixture(id: "two", date: Date(timeIntervalSince1970: 200))
        ])

        let viewModel = TimelineViewModel(repository: repository, calendar: Calendar(identifier: .gregorian))
        await viewModel.load()

        XCTAssertEqual(viewModel.sections.flatMap(\.memories).map(\.id), ["two", "one"])
        XCTAssertNil(viewModel.errorMessage)
    }

    func testEmptyRepositorySetsEmptyState() async {
        let viewModel = TimelineViewModel(repository: InMemoryMemoryRepository(memories: []))
        await viewModel.load()

        XCTAssertTrue(viewModel.sections.isEmpty)
        XCTAssertTrue(viewModel.isEmpty)
    }
}

private final class InMemoryMemoryRepository: MemoryRepositoryProtocol {
    var memories: [FamilyMemory]

    init(memories: [FamilyMemory]) {
        self.memories = memories
    }

    func fetchAll() throws -> [FamilyMemory] {
        memories.sorted { $0.date > $1.date }
    }

    func fetch(id: String) throws -> FamilyMemory? {
        memories.first { $0.id == id }
    }

    func save(_ memory: FamilyMemory) throws {
        memories.removeAll { $0.id == memory.id }
        memories.append(memory)
    }

    func delete(id: String) throws {
        memories.removeAll { $0.id == id }
    }
}

private extension FamilyMemory {
    static func fixture(id: String, date: Date) -> FamilyMemory {
        FamilyMemory(
            id: id,
            originalFilename: "\(id).jpg",
            originalPath: "Originals/\(id).jpg",
            thumbnailPath: "Thumbnails/\(id).jpg",
            story: "",
            date: date,
            people: [],
            filter: "original",
            createdAt: date,
            updatedAt: date,
            sourceCreatedAt: date,
            sourceAssetIdentifier: nil
        )
    }
}
```

- [ ] **Step 2: Run tests and verify failure**

Run:

```bash
xcodebuild \
  -project ios/FamilyMemories/FamilyMemories.xcodeproj \
  -scheme FamilyMemories \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:FamilyMemoriesTests/TimelineViewModelTests \
  test
```

Expected: tests fail because `MemoryRepositoryProtocol` and `TimelineViewModel` do not exist.

- [ ] **Step 3: Add repository protocol and environment**

Modify `ios/FamilyMemories/FamilyMemories/Persistence/MemoryRepository.swift` to include the protocol above the class:

```swift
import Foundation
import SwiftData

@MainActor
protocol MemoryRepositoryProtocol {
    func fetchAll() throws -> [FamilyMemory]
    func fetch(id: String) throws -> FamilyMemory?
    func save(_ memory: FamilyMemory) throws
    func delete(id: String) throws
}

@MainActor
final class MemoryRepository: MemoryRepositoryProtocol {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll() throws -> [FamilyMemory] {
        let descriptor = FetchDescriptor<MemoryRecord>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try context.fetch(descriptor).map(\.domain)
    }

    func fetch(id: String) throws -> FamilyMemory? {
        let descriptor = FetchDescriptor<MemoryRecord>(
            predicate: #Predicate { $0.id == id }
        )
        return try context.fetch(descriptor).first?.domain
    }

    func save(_ memory: FamilyMemory) throws {
        let descriptor = FetchDescriptor<MemoryRecord>(
            predicate: #Predicate { $0.id == memory.id }
        )

        if let existing = try context.fetch(descriptor).first {
            existing.apply(memory)
        } else {
            context.insert(MemoryRecord(memory: memory))
        }

        try context.save()
    }

    func delete(id: String) throws {
        let descriptor = FetchDescriptor<MemoryRecord>(
            predicate: #Predicate { $0.id == id }
        )

        for record in try context.fetch(descriptor) {
            context.delete(record)
        }

        try context.save()
    }
}
```

Create `ios/FamilyMemories/FamilyMemories/App/AppEnvironment.swift`:

```swift
import Foundation
import SwiftData

@MainActor
final class AppEnvironment: ObservableObject {
    let fileStore: MemoryFileStore
    let repository: MemoryRepository
    let importService: PhotoImportService

    init(modelContext: ModelContext) throws {
        let fileStore = try MemoryFileStore()
        self.fileStore = fileStore
        self.repository = MemoryRepository(context: modelContext)
        self.importService = PhotoImportService(fileStore: fileStore)
    }
}
```

- [ ] **Step 4: Add timeline view model**

Create `ios/FamilyMemories/FamilyMemories/Features/Timeline/TimelineViewModel.swift`:

```swift
import Combine
import Foundation

@MainActor
final class TimelineViewModel: ObservableObject {
    @Published private(set) var sections: [TimelineSection] = []
    @Published private(set) var errorMessage: String?
    @Published private(set) var isLoading = false

    private let repository: MemoryRepositoryProtocol
    private let calendar: Calendar

    var isEmpty: Bool {
        sections.isEmpty && isLoading == false
    }

    init(repository: MemoryRepositoryProtocol, calendar: Calendar = .current) {
        self.repository = repository
        self.calendar = calendar
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let memories = try repository.fetchAll()
            sections = TimelineGrouping.sections(for: memories, calendar: calendar)
            errorMessage = nil
        } catch {
            sections = []
            errorMessage = error.localizedDescription
        }
    }
}
```

- [ ] **Step 5: Run timeline view model tests**

Run:

```bash
xcodebuild \
  -project ios/FamilyMemories/FamilyMemories.xcodeproj \
  -scheme FamilyMemories \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:FamilyMemoriesTests/TimelineViewModelTests \
  test
```

Expected: all `TimelineViewModelTests` pass.

- [ ] **Step 6: Commit timeline state layer**

```bash
git add ios/FamilyMemories/FamilyMemories/App/AppEnvironment.swift ios/FamilyMemories/FamilyMemories/Features/Timeline/TimelineViewModel.swift ios/FamilyMemories/FamilyMemories/Persistence/MemoryRepository.swift ios/FamilyMemories/FamilyMemoriesTests/TimelineViewModelTests.swift
git commit -m "feat: add timeline state layer"
```

## Task 7: Timeline, Import Review, And Memory Detail UI

**Files:**
- Create: `ios/FamilyMemories/FamilyMemories/Features/Timeline/TimelineView.swift`
- Create: `ios/FamilyMemories/FamilyMemories/Features/Timeline/MemoryThumbnailView.swift`
- Create: `ios/FamilyMemories/FamilyMemories/Features/ImportReview/ImportReviewView.swift`
- Create: `ios/FamilyMemories/FamilyMemories/Features/MemoryDetail/MemoryDetailView.swift`
- Modify: `ios/FamilyMemories/FamilyMemories/App/AppRootView.swift`
- Modify: `ios/FamilyMemories/FamilyMemoriesUITests/FamilyMemoriesUITests.swift`

- [ ] **Step 1: Write failing UI smoke tests**

Replace `ios/FamilyMemories/FamilyMemoriesUITests/FamilyMemoriesUITests.swift` with:

```swift
import XCTest

final class FamilyMemoriesUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testEmptyTimelineShowsImportAction() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-reset-data"]
        app.launch()

        XCTAssertTrue(app.staticTexts["timeline.empty.title"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["timeline.import"].exists)
    }

    func testTabsAreReachable() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-reset-data"]
        app.launch()

        XCTAssertTrue(app.tabBars.buttons["tab.timeline"].exists)
        app.tabBars.buttons["tab.album"].tap()
        XCTAssertTrue(app.staticTexts["album.empty.title"].waitForExistence(timeout: 2))
        app.tabBars.buttons["tab.settings"].tap()
        XCTAssertTrue(app.staticTexts["settings.title"].waitForExistence(timeout: 2))
    }
}
```

- [ ] **Step 2: Run UI tests and verify failure**

Run:

```bash
xcodebuild \
  -project ios/FamilyMemories/FamilyMemories.xcodeproj \
  -scheme FamilyMemories \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:FamilyMemoriesUITests \
  test
```

Expected: tests fail because the import action and final screen views are not implemented.

- [ ] **Step 3: Add reusable thumbnail view**

Create `ios/FamilyMemories/FamilyMemories/Features/Timeline/MemoryThumbnailView.swift`:

```swift
import SwiftUI

struct MemoryThumbnailView: View {
    let imageURL: URL?

    var body: some View {
        Group {
            if let imageURL, let uiImage = UIImage(contentsOfFile: imageURL.path) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Rectangle().fill(.secondary.opacity(0.12))
                    Image(systemName: "photo")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(width: 88, height: 88)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .accessibilityHidden(true)
    }
}
```

- [ ] **Step 4: Add timeline screen**

Create `ios/FamilyMemories/FamilyMemories/Features/Timeline/TimelineView.swift`:

```swift
import PhotosUI
import SwiftUI

struct TimelineView: View {
    @StateObject private var viewModel: TimelineViewModel
    let fileStore: MemoryFileStore
    let onImport: () -> Void
    let onOpenMemory: (FamilyMemory) -> Void

    init(
        repository: MemoryRepositoryProtocol,
        fileStore: MemoryFileStore,
        onImport: @escaping () -> Void,
        onOpenMemory: @escaping (FamilyMemory) -> Void
    ) {
        _viewModel = StateObject(wrappedValue: TimelineViewModel(repository: repository))
        self.fileStore = fileStore
        self.onImport = onImport
        self.onOpenMemory = onOpenMemory
    }

    var body: some View {
        Group {
            if viewModel.isEmpty {
                ContentUnavailableView {
                    Label("timeline.empty.title", systemImage: "photo.on.rectangle")
                } description: {
                    Text("timeline.empty.body")
                } actions: {
                    Button("timeline.import", action: onImport)
                        .buttonStyle(.borderedProminent)
                }
            } else {
                List {
                    ForEach(viewModel.sections) { section in
                        Section("\(section.year).\(String(format: "%02d", section.month))") {
                            ForEach(section.memories) { memory in
                                Button {
                                    onOpenMemory(memory)
                                } label: {
                                    HStack(spacing: 12) {
                                        MemoryThumbnailView(imageURL: fileStore.url(forRelativePath: memory.thumbnailPath))
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(memory.date, style: .date)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                            Text(memory.story.isEmpty ? String(localized: "memory.story.empty") : memory.story)
                                                .font(.body)
                                                .lineLimit(2)
                                            if memory.people.isEmpty == false {
                                                Text(memory.people.joined(separator: " · "))
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                                    .lineLimit(1)
                                            }
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("tab.timeline")
        .toolbar {
            Button(action: onImport) {
                Label("timeline.import", systemImage: "plus")
            }
        }
        .task {
            await viewModel.load()
        }
    }
}
```

- [ ] **Step 5: Add import review screen**

Create `ios/FamilyMemories/FamilyMemories/Features/ImportReview/ImportReviewView.swift`:

```swift
import SwiftUI

struct ImportReviewView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var drafts: [MemoryDraft]
    let repository: MemoryRepositoryProtocol

    init(drafts: [MemoryDraft], repository: MemoryRepositoryProtocol) {
        _drafts = State(initialValue: drafts)
        self.repository = repository
    }

    var body: some View {
        NavigationStack {
            List($drafts) { $draft in
                VStack(alignment: .leading, spacing: 10) {
                    DatePicker("memory.date", selection: $draft.date, displayedComponents: .date)
                    TextField("memory.people", text: Binding(
                        get: { draft.people.joined(separator: ", ") },
                        set: { draft.people = PeopleTagNormalizer.normalize($0.split(separator: ",").map(String.init)) }
                    ))
                    TextField("memory.story", text: $draft.story, axis: .vertical)
                        .lineLimit(3...8)
                }
                .padding(.vertical, 8)
            }
            .navigationTitle("import.review.title")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.done") {
                        saveDrafts()
                        dismiss()
                    }
                }
            }
        }
    }

    private func saveDrafts() {
        for draft in drafts {
            try? repository.save(draft.persisted())
        }
    }
}
```

- [ ] **Step 6: Add memory detail screen**

Create `ios/FamilyMemories/FamilyMemories/Features/MemoryDetail/MemoryDetailView.swift`:

```swift
import SwiftUI

struct MemoryDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var memory: FamilyMemory
    let repository: MemoryRepositoryProtocol
    let fileStore: MemoryFileStore

    init(memory: FamilyMemory, repository: MemoryRepositoryProtocol, fileStore: MemoryFileStore) {
        _memory = State(initialValue: memory)
        self.repository = repository
        self.fileStore = fileStore
    }

    var body: some View {
        Form {
            Section {
                MemoryThumbnailView(imageURL: fileStore.url(forRelativePath: memory.originalPath))
                    .frame(maxWidth: .infinity)
                    .frame(height: 280)
            }

            Section("memory.metadata") {
                DatePicker("memory.date", selection: $memory.date, displayedComponents: .date)
                TextField("memory.people", text: Binding(
                    get: { memory.people.joined(separator: ", ") },
                    set: { memory.people = PeopleTagNormalizer.normalize($0.split(separator: ",").map(String.init)) }
                ))
                TextField("memory.story", text: $memory.story, axis: .vertical)
                    .lineLimit(4...12)
            }

            Section {
                Button(role: .destructive) {
                    try? repository.delete(id: memory.id)
                    try? fileStore.deleteMemoryFiles(
                        originalRelativePath: memory.originalPath,
                        thumbnailRelativePath: memory.thumbnailPath
                    )
                    dismiss()
                } label: {
                    Label("memory.delete", systemImage: "trash")
                }
            }
        }
        .navigationTitle("memory.detail.title")
        .toolbar {
            Button("common.save") {
                try? repository.save(memory)
                dismiss()
            }
        }
    }
}
```

- [ ] **Step 7: Wire root navigation**

Modify `ios/FamilyMemories/FamilyMemories/App/AppRootView.swift`:

```swift
import SwiftData
import SwiftUI

struct AppRootView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var environment: AppEnvironment?
    @State private var presentedDrafts: [MemoryDraft] = []
    @State private var selectedMemory: FamilyMemory?

    var body: some View {
        Group {
            if let environment {
                TabView {
                    NavigationStack {
                        TimelineView(
                            repository: environment.repository,
                            fileStore: environment.fileStore,
                            onImport: { presentedDrafts = [] },
                            onOpenMemory: { selectedMemory = $0 }
                        )
                        .navigationDestination(item: $selectedMemory) { memory in
                            MemoryDetailView(
                                memory: memory,
                                repository: environment.repository,
                                fileStore: environment.fileStore
                            )
                        }
                    }
                    .tabItem {
                        Label("tab.timeline", systemImage: "clock")
                    }

                    NavigationStack {
                        Text("album.empty.title")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    .tabItem {
                        Label("tab.album", systemImage: "book.pages")
                    }

                    NavigationStack {
                        Text("settings.title")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    .tabItem {
                        Label("tab.settings", systemImage: "gearshape")
                    }
                }
            } else {
                ProgressView()
                    .task {
                        environment = try? AppEnvironment(modelContext: modelContext)
                    }
            }
        }
    }
}
```

- [ ] **Step 8: Run UI smoke tests**

Run:

```bash
xcodebuild \
  -project ios/FamilyMemories/FamilyMemories.xcodeproj \
  -scheme FamilyMemories \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:FamilyMemoriesUITests \
  test
```

Expected: empty timeline and tab smoke tests pass.

- [ ] **Step 9: Commit core UI**

```bash
git add ios/FamilyMemories/FamilyMemories/App/AppRootView.swift ios/FamilyMemories/FamilyMemories/Features ios/FamilyMemories/FamilyMemoriesUITests/FamilyMemoriesUITests.swift
git commit -m "feat: add timeline and memory editing ui"
```

## Task 8: PhotosPicker Integration

**Files:**
- Modify: `ios/FamilyMemories/FamilyMemories/Features/Timeline/TimelineView.swift`
- Modify: `ios/FamilyMemories/FamilyMemories/App/AppRootView.swift`
- Create: `ios/FamilyMemories/FamilyMemories/Importing/PhotosPickerAdapter.swift`

- [ ] **Step 1: Add adapter for PhotosPicker items**

Create `ios/FamilyMemories/FamilyMemories/Importing/PhotosPickerAdapter.swift`:

```swift
import Foundation
import PhotosUI
import SwiftUI

enum PhotosPickerAdapter {
    static func loadPickedPhotoData(from items: [PhotosPickerItem]) async -> [PickedPhotoData] {
        var loaded: [PickedPhotoData] = []

        for item in items {
            guard let data = try? await item.loadTransferable(type: Data.self) else {
                continue
            }

            loaded.append(
                PickedPhotoData(
                    filename: item.itemIdentifier.map { "\($0).jpg" } ?? "\(UUID().uuidString).jpg",
                    imageData: data,
                    sourceCreatedAt: nil,
                    sourceAssetIdentifier: item.itemIdentifier
                )
            )
        }

        return loaded
    }
}
```

- [ ] **Step 2: Add PhotosPicker to timeline**

Modify `ios/FamilyMemories/FamilyMemories/Features/Timeline/TimelineView.swift` so the import toolbar item uses `PhotosPicker`:

```swift
import PhotosUI
import SwiftUI

struct TimelineView: View {
    @StateObject private var viewModel: TimelineViewModel
    @State private var selectedItems: [PhotosPickerItem] = []
    let fileStore: MemoryFileStore
    let importService: PhotoImportService
    let onImportedDrafts: ([MemoryDraft]) -> Void
    let onOpenMemory: (FamilyMemory) -> Void

    init(
        repository: MemoryRepositoryProtocol,
        fileStore: MemoryFileStore,
        importService: PhotoImportService,
        onImportedDrafts: @escaping ([MemoryDraft]) -> Void,
        onOpenMemory: @escaping (FamilyMemory) -> Void
    ) {
        _viewModel = StateObject(wrappedValue: TimelineViewModel(repository: repository))
        self.fileStore = fileStore
        self.importService = importService
        self.onImportedDrafts = onImportedDrafts
        self.onOpenMemory = onOpenMemory
    }

    var body: some View {
        content
            .navigationTitle("tab.timeline")
            .toolbar {
                PhotosPicker(
                    selection: $selectedItems,
                    maxSelectionCount: 50,
                    matching: .images
                ) {
                    Label("timeline.import", systemImage: "plus")
                }
            }
            .task {
                await viewModel.load()
            }
            .onChange(of: selectedItems) { _, newItems in
                Task {
                    let picked = await PhotosPickerAdapter.loadPickedPhotoData(from: newItems)
                    let result = try? importService.importPhotos(picked)
                    onImportedDrafts(result?.drafts ?? [])
                    selectedItems = []
                }
            }
    }

    private var content: some View {
        Group {
            if viewModel.isEmpty {
                ContentUnavailableView {
                    Label("timeline.empty.title", systemImage: "photo.on.rectangle")
                } description: {
                    Text("timeline.empty.body")
                } actions: {
                    PhotosPicker(
                        selection: $selectedItems,
                        maxSelectionCount: 50,
                        matching: .images
                    ) {
                        Text("timeline.import")
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                List {
                    ForEach(viewModel.sections) { section in
                        Section("\(section.year).\(String(format: "%02d", section.month))") {
                            ForEach(section.memories) { memory in
                                Button {
                                    onOpenMemory(memory)
                                } label: {
                                    HStack(spacing: 12) {
                                        MemoryThumbnailView(imageURL: fileStore.url(forRelativePath: memory.thumbnailPath))
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(memory.date, style: .date)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                            Text(memory.story.isEmpty ? String(localized: "memory.story.empty") : memory.story)
                                                .font(.body)
                                                .lineLimit(2)
                                            if memory.people.isEmpty == false {
                                                Text(memory.people.joined(separator: " · "))
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                                    .lineLimit(1)
                                            }
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
```

- [ ] **Step 3: Present import review after picker import**

Modify `ios/FamilyMemories/FamilyMemories/App/AppRootView.swift` to pass `importService` and present review:

```swift
TimelineView(
    repository: environment.repository,
    fileStore: environment.fileStore,
    importService: environment.importService,
    onImportedDrafts: { drafts in
        presentedDrafts = drafts
    },
    onOpenMemory: { selectedMemory = $0 }
)
.sheet(isPresented: Binding(
    get: { presentedDrafts.isEmpty == false },
    set: { if $0 == false { presentedDrafts = [] } }
)) {
    ImportReviewView(drafts: presentedDrafts, repository: environment.repository)
}
```

- [ ] **Step 4: Build the app**

Run:

```bash
xcodebuild \
  -project ios/FamilyMemories/FamilyMemories.xcodeproj \
  -scheme FamilyMemories \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build
```

Expected: build succeeds. Manual simulator test: tapping the import button opens the system picker.

- [ ] **Step 5: Commit picker integration**

```bash
git add ios/FamilyMemories/FamilyMemories/Importing/PhotosPickerAdapter.swift ios/FamilyMemories/FamilyMemories/Features/Timeline/TimelineView.swift ios/FamilyMemories/FamilyMemories/App/AppRootView.swift
git commit -m "feat: connect timeline import to photos picker"
```

## Task 9: Backup Package Export And Import

**Files:**
- Create: `ios/FamilyMemories/FamilyMemories/Backup/BackupManifest.swift`
- Create: `ios/FamilyMemories/FamilyMemories/Backup/BackupMemoryDTO.swift`
- Create: `ios/FamilyMemories/FamilyMemories/Backup/BackupPackageService.swift`
- Create: `ios/FamilyMemories/FamilyMemories/Resources/FamilyMemoriesUTTypes.swift`
- Create: `ios/FamilyMemories/FamilyMemoriesTests/BackupPackageServiceTests.swift`
- Modify: `ios/FamilyMemories/FamilyMemories.xcodeproj`

- [ ] **Step 1: Add ZIPFoundation dependency**

In Xcode, add Swift Package dependency:

```text
Package URL: https://github.com/weichsel/ZIPFoundation.git
Product: ZIPFoundation
Targets: FamilyMemories, FamilyMemoriesTests
```

Then run:

```bash
xcodebuild \
  -project ios/FamilyMemories/FamilyMemories.xcodeproj \
  -scheme FamilyMemories \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build
```

Expected: build succeeds and `Package.resolved` records ZIPFoundation.

- [ ] **Step 2: Write failing backup tests**

Create `ios/FamilyMemories/FamilyMemoriesTests/BackupPackageServiceTests.swift`:

```swift
import XCTest
@testable import FamilyMemories

final class BackupPackageServiceTests: XCTestCase {
    private var rootURL: URL!
    private var store: MemoryFileStore!

    override func setUpWithError() throws {
        rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        store = try MemoryFileStore(rootURL: rootURL)
    }

    override func tearDownWithError() throws {
        if let rootURL {
            try? FileManager.default.removeItem(at: rootURL)
        }
    }

    func testExportCreatesBackupPackageWithManifestAndMemories() throws {
        let paths = try store.writeImageFiles(
            memoryID: "memory-1",
            originalFilename: "memory.jpg",
            originalData: Data([1, 2, 3]),
            thumbnailData: Data([4, 5, 6])
        )
        let memory = FamilyMemory(
            id: "memory-1",
            originalFilename: "memory.jpg",
            originalPath: paths.originalRelativePath,
            thumbnailPath: paths.thumbnailRelativePath,
            story: "Dinner together",
            date: Date(timeIntervalSince1970: 100),
            people: ["Mom"],
            filter: "original",
            createdAt: Date(timeIntervalSince1970: 90),
            updatedAt: Date(timeIntervalSince1970: 95),
            sourceCreatedAt: Date(timeIntervalSince1970: 80),
            sourceAssetIdentifier: nil
        )

        let service = BackupPackageService(fileStore: store)
        let backupURL = try service.exportBackup(memories: [memory], localeIdentifier: "zh-Hans")

        XCTAssertEqual(backupURL.pathExtension, "familymemories")
        let summary = try service.validateBackup(at: backupURL)
        XCTAssertEqual(summary.memoryCount, 1)
        XCTAssertEqual(summary.localeIdentifier, "zh-Hans")
    }

    func testInvalidBackupDoesNotProduceImportPayload() throws {
        let invalidURL = rootURL.appendingPathComponent("bad.familymemories")
        try Data([0]).write(to: invalidURL)

        let service = BackupPackageService(fileStore: store)

        XCTAssertThrowsError(try service.validateBackup(at: invalidURL))
    }
}
```

- [ ] **Step 3: Add backup models and UTType**

Create `ios/FamilyMemories/FamilyMemories/Backup/BackupManifest.swift`:

```swift
import Foundation

struct BackupManifest: Codable, Equatable {
    let appName: String
    let backupVersion: Int
    let createdAt: Date
    let memoryCount: Int
    let locale: String
    let minimumSupportedAppVersion: String
}

struct BackupSummary: Equatable {
    let memoryCount: Int
    let localeIdentifier: String
    let createdAt: Date
}
```

Create `ios/FamilyMemories/FamilyMemories/Backup/BackupMemoryDTO.swift`:

```swift
import Foundation

struct BackupMemoryDTO: Codable, Equatable {
    let id: String
    let originalFilename: String
    let originalPath: String
    let thumbnailPath: String
    let story: String
    let date: Date
    let people: [String]
    let filter: String
    let createdAt: Date
    let updatedAt: Date
    let sourceCreatedAt: Date?
    let sourceAssetIdentifier: String?

    init(memory: FamilyMemory) {
        id = memory.id
        originalFilename = memory.originalFilename
        originalPath = memory.originalPath
        thumbnailPath = memory.thumbnailPath
        story = memory.story
        date = memory.date
        people = memory.people
        filter = memory.filter
        createdAt = memory.createdAt
        updatedAt = memory.updatedAt
        sourceCreatedAt = memory.sourceCreatedAt
        sourceAssetIdentifier = memory.sourceAssetIdentifier
    }

    var domain: FamilyMemory {
        FamilyMemory(
            id: id,
            originalFilename: originalFilename,
            originalPath: originalPath,
            thumbnailPath: thumbnailPath,
            story: story,
            date: date,
            people: PeopleTagNormalizer.normalize(people),
            filter: filter,
            createdAt: createdAt,
            updatedAt: updatedAt,
            sourceCreatedAt: sourceCreatedAt,
            sourceAssetIdentifier: sourceAssetIdentifier
        )
    }
}
```

Create `ios/FamilyMemories/FamilyMemories/Resources/FamilyMemoriesUTTypes.swift`:

```swift
import UniformTypeIdentifiers

extension UTType {
    static let familyMemoriesBackup = UTType(exportedAs: "com.ksharpr.familymemories.backup")
}
```

- [ ] **Step 4: Implement package service**

Create `ios/FamilyMemories/FamilyMemories/Backup/BackupPackageService.swift`:

```swift
import Foundation
import ZIPFoundation

enum BackupPackageError: Error {
    case invalidArchive
    case missingManifest
    case missingMemories
    case unsupportedVersion(Int)
}

final class BackupPackageService {
    private let fileStore: MemoryFileStore
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(fileStore: MemoryFileStore) {
        self.fileStore = fileStore
        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
    }

    func exportBackup(memories: [FamilyMemory], localeIdentifier: String) throws -> URL {
        let filename = "family-memories-\(Self.timestamp()).familymemories"
        let archiveURL = fileStore.backupsDirectory.appendingPathComponent(filename)
        if FileManager.default.fileExists(atPath: archiveURL.path) {
            try FileManager.default.removeItem(at: archiveURL)
        }

        guard let archive = Archive(url: archiveURL, accessMode: .create) else {
            throw BackupPackageError.invalidArchive
        }

        let manifest = BackupManifest(
            appName: "Family Memories",
            backupVersion: 1,
            createdAt: Date(),
            memoryCount: memories.count,
            locale: localeIdentifier,
            minimumSupportedAppVersion: "0.1.0"
        )
        try archive.addData(try encoder.encode(manifest), path: "manifest.json")
        try archive.addData(try encoder.encode(memories.map(BackupMemoryDTO.init(memory:))), path: "memories.json")

        for memory in memories {
            try archive.addFileIfPresent(
                sourceURL: fileStore.url(forRelativePath: memory.originalPath),
                path: memory.originalPath
            )
            try archive.addFileIfPresent(
                sourceURL: fileStore.url(forRelativePath: memory.thumbnailPath),
                path: memory.thumbnailPath
            )
        }

        return archiveURL
    }

    func validateBackup(at url: URL) throws -> BackupSummary {
        guard let archive = Archive(url: url, accessMode: .read) else {
            throw BackupPackageError.invalidArchive
        }
        let manifestData = try archive.data(for: "manifest.json")
        let memoriesData = try archive.data(for: "memories.json")
        let manifest = try decoder.decode(BackupManifest.self, from: manifestData)
        _ = try decoder.decode([BackupMemoryDTO].self, from: memoriesData)

        guard manifest.backupVersion == 1 else {
            throw BackupPackageError.unsupportedVersion(manifest.backupVersion)
        }

        return BackupSummary(
            memoryCount: manifest.memoryCount,
            localeIdentifier: manifest.locale,
            createdAt: manifest.createdAt
        )
    }

    private static func timestamp() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withTime, .withDashSeparatorInDate]
        return formatter.string(from: Date()).replacingOccurrences(of: ":", with: "-")
    }
}

private extension Archive {
    func addData(_ data: Data, path: String) throws {
        try addEntry(
            with: path,
            type: .file,
            uncompressedSize: UInt32(data.count),
            provider: { position, size -> Data in
                let start = Int(position)
                return data.subdata(in: start..<start + size)
            }
        )
    }

    func addFileIfPresent(sourceURL: URL, path: String) throws {
        guard FileManager.default.fileExists(atPath: sourceURL.path) else { return }
        try addEntry(with: path, fileURL: sourceURL)
    }

    func data(for path: String) throws -> Data {
        guard let entry = self[path] else {
            if path == "manifest.json" { throw BackupPackageError.missingManifest }
            throw BackupPackageError.missingMemories
        }

        var data = Data()
        _ = try extract(entry) { chunk in
            data.append(chunk)
        }
        return data
    }
}
```

- [ ] **Step 5: Run backup tests**

Run:

```bash
xcodebuild \
  -project ios/FamilyMemories/FamilyMemories.xcodeproj \
  -scheme FamilyMemories \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:FamilyMemoriesTests/BackupPackageServiceTests \
  test
```

Expected: all `BackupPackageServiceTests` pass.

- [ ] **Step 6: Commit backup package service**

```bash
git add ios/FamilyMemories/FamilyMemories/Backup ios/FamilyMemories/FamilyMemories/Resources ios/FamilyMemories/FamilyMemories.xcodeproj ios/FamilyMemories/FamilyMemoriesTests/BackupPackageServiceTests.swift
git commit -m "feat: add manual backup package export"
```

## Task 10: Album Reader, Settings, Language Switch, And Backup Entry Points

**Files:**
- Create: `ios/FamilyMemories/FamilyMemories/Features/Album/AlbumReaderView.swift`
- Create: `ios/FamilyMemories/FamilyMemories/Features/Settings/SettingsView.swift`
- Create: `ios/FamilyMemories/FamilyMemories/Localization/AppLanguage.swift`
- Create: `ios/FamilyMemories/FamilyMemories/Localization/Localizable.xcstrings`
- Modify: `ios/FamilyMemories/FamilyMemories/App/AppRootView.swift`
- Modify: `ios/FamilyMemories/FamilyMemoriesUITests/FamilyMemoriesUITests.swift`

- [ ] **Step 1: Write failing language UI test**

Append this test to `ios/FamilyMemories/FamilyMemoriesUITests/FamilyMemoriesUITests.swift`:

```swift
func testLanguageSwitchChangesUiCopy() throws {
    let app = XCUIApplication()
    app.launchArguments = ["-ui-testing", "-reset-data"]
    app.launch()

    app.tabBars.buttons["设置"].tap()
    XCTAssertTrue(app.segmentedControls.buttons["English"].exists)
    app.segmentedControls.buttons["English"].tap()
    XCTAssertTrue(app.staticTexts["Settings"].waitForExistence(timeout: 2))
    app.segmentedControls.buttons["中文"].tap()
    XCTAssertTrue(app.staticTexts["设置"].waitForExistence(timeout: 2))
}
```

- [ ] **Step 2: Run language UI test and verify failure**

Run:

```bash
xcodebuild \
  -project ios/FamilyMemories/FamilyMemories.xcodeproj \
  -scheme FamilyMemories \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:FamilyMemoriesUITests/testLanguageSwitchChangesUiCopy \
  test
```

Expected: test fails because settings and language state are not implemented.

- [ ] **Step 3: Add language model**

Create `ios/FamilyMemories/FamilyMemories/Localization/AppLanguage.swift`:

```swift
import Foundation
import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case chinese = "zh-Hans"
    case english = "en"

    var id: String { rawValue }

    var locale: Locale {
        Locale(identifier: rawValue)
    }

    var displayName: LocalizedStringKey {
        switch self {
        case .chinese:
            return "settings.language.chinese"
        case .english:
            return "settings.language.english"
        }
    }
}
```

- [ ] **Step 4: Add album reader**

Create `ios/FamilyMemories/FamilyMemories/Features/Album/AlbumReaderView.swift`:

```swift
import SwiftUI

struct AlbumReaderView: View {
    let memories: [FamilyMemory]
    let fileStore: MemoryFileStore

    var body: some View {
        Group {
            if memories.isEmpty {
                ContentUnavailableView("album.empty.title", systemImage: "book.pages")
            } else {
                TabView {
                    ForEach(memories) { memory in
                        VStack(spacing: 16) {
                            MemoryThumbnailView(imageURL: fileStore.url(forRelativePath: memory.originalPath))
                                .frame(maxWidth: .infinity)
                                .frame(height: 360)
                            Text(memory.date, style: .date)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(memory.story.isEmpty ? String(localized: "memory.story.empty") : memory.story)
                                .font(.body)
                                .multilineTextAlignment(.center)
                            if memory.people.isEmpty == false {
                                Text(memory.people.joined(separator: " · "))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding()
                    }
                }
                .tabViewStyle(.page)
            }
        }
        .navigationTitle("tab.album")
    }
}
```

- [ ] **Step 5: Add settings screen**

Create `ios/FamilyMemories/FamilyMemories/Features/Settings/SettingsView.swift`:

```swift
import SwiftUI

struct SettingsView: View {
    @Binding var language: AppLanguage
    let onExportBackup: () -> Void
    let onImportBackup: () -> Void

    var body: some View {
        Form {
            Section("settings.language") {
                Picker("settings.language", selection: $language) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.displayName).tag(language)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("settings.backup") {
                Button(action: onExportBackup) {
                    Label("settings.exportBackup", systemImage: "square.and.arrow.up")
                }
                Button(action: onImportBackup) {
                    Label("settings.importBackup", systemImage: "square.and.arrow.down")
                }
            }

            Section("settings.privacy") {
                Text("settings.privacy.body")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("settings.title")
    }
}
```

- [ ] **Step 6: Add localized strings**

Create `ios/FamilyMemories/FamilyMemories/Localization/Localizable.xcstrings` with these keys translated in English and Simplified Chinese:

```json
{
  "sourceLanguage" : "en",
  "strings" : {
    "album.empty.title" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "No memories yet" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "还没有回忆" } }
      }
    },
    "common.cancel" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Cancel" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "取消" } }
      }
    },
    "common.done" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Done" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "完成" } }
      }
    },
    "common.save" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Save" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "保存" } }
      }
    },
    "import.review.title" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Review import" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "确认导入" } }
      }
    },
    "memory.date" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Date" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "日期" } }
      }
    },
    "memory.delete" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Delete memory" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "删除回忆" } }
      }
    },
    "memory.detail.title" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Memory" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "回忆" } }
      }
    },
    "memory.metadata" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Details" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "详情" } }
      }
    },
    "memory.people" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "People" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "人物" } }
      }
    },
    "memory.story" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Story" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "故事" } }
      }
    },
    "memory.story.empty" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "No story yet" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "还没有故事" } }
      }
    },
    "settings.backup" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Backup" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "备份" } }
      }
    },
    "settings.exportBackup" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Export backup" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "导出备份" } }
      }
    },
    "settings.importBackup" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Import backup" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "导入备份" } }
      }
    },
    "settings.language" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Language" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "语言" } }
      }
    },
    "settings.language.chinese" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "中文" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "中文" } }
      }
    },
    "settings.language.english" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "English" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "English" } }
      }
    },
    "settings.privacy" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Privacy" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "隐私" } }
      }
    },
    "settings.privacy.body" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Selected photos are copied into this app on this device. No account, server, or automatic upload is used. Backups are created only when you export them." } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "你选择的照片会复制到本机 App 内。这里不需要账号，不使用服务器，也不会自动上传。只有你主动导出时才会创建备份。" } }
      }
    },
    "settings.title" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Settings" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "设置" } }
      }
    },
    "tab.album" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Album" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "相册" } }
      }
    },
    "tab.settings" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Settings" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "设置" } }
      }
    },
    "tab.timeline" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Timeline" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "时间线" } }
      }
    },
    "timeline.empty.body" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Choose meaningful photos from your library and add stories, dates, and people." } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "从照片图库中选择有意义的照片，再补充故事、日期和人物。" } }
      }
    },
    "timeline.empty.title" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Start your family memories" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "开始整理家族回忆" } }
      }
    },
    "timeline.import" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Import photos" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "导入照片" } }
      }
    }
  },
  "version" : "1.0"
}
```

- [ ] **Step 7: Wire album and settings into root**

Modify `ios/FamilyMemories/FamilyMemories/App/AppRootView.swift` to hold language state, pass it as environment locale, and use `AlbumReaderView` plus `SettingsView`:

```swift
@State private var language: AppLanguage = .chinese

// Apply to the outer Group:
.environment(\.locale, language.locale)

// Album tab content:
NavigationStack {
    AlbumReaderView(memories: [], fileStore: environment.fileStore)
}

// Settings tab content:
NavigationStack {
    SettingsView(
        language: $language,
        onExportBackup: {},
        onImportBackup: {}
    )
}
```

Use the current repository memories when wiring `AlbumReaderView`; if the view needs loading state, add a small `AlbumReaderViewModel` that calls `repository.fetchAll()` and sorts descending by `date`.

- [ ] **Step 8: Run language UI test**

Run:

```bash
xcodebuild \
  -project ios/FamilyMemories/FamilyMemories.xcodeproj \
  -scheme FamilyMemories \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:FamilyMemoriesUITests/testLanguageSwitchChangesUiCopy \
  test
```

Expected: language switch UI test passes, and user-entered memory story/people strings remain unchanged because only UI copy uses localized keys.

- [ ] **Step 9: Commit reader, settings, and localization**

```bash
git add ios/FamilyMemories/FamilyMemories/Features/Album ios/FamilyMemories/FamilyMemories/Features/Settings ios/FamilyMemories/FamilyMemories/Localization ios/FamilyMemories/FamilyMemories/App/AppRootView.swift ios/FamilyMemories/FamilyMemoriesUITests/FamilyMemoriesUITests.swift
git commit -m "feat: add album reader settings and localization"
```

## Task 11: Backup UI, Documentation, And Full Verification

**Files:**
- Modify: `ios/FamilyMemories/FamilyMemories/Features/Settings/SettingsView.swift`
- Modify: `ios/FamilyMemories/FamilyMemories/App/AppRootView.swift`
- Modify: `README.md`

- [ ] **Step 1: Wire backup actions to Settings**

Modify `AppEnvironment` to include backup service:

```swift
let backupService: BackupPackageService

// inside init(modelContext:)
self.backupService = BackupPackageService(fileStore: fileStore)
```

Modify `AppRootView` backup closures:

```swift
@State private var exportedBackupURL: URL?
@State private var isImportingBackup = false

SettingsView(
    language: $language,
    onExportBackup: {
        if let memories = try? environment.repository.fetchAll() {
            exportedBackupURL = try? environment.backupService.exportBackup(
                memories: memories,
                localeIdentifier: language.rawValue
            )
        }
    },
    onImportBackup: {
        isImportingBackup = true
    }
)
.sheet(item: $exportedBackupURL) { url in
    ShareLink(item: url) {
        Label("settings.exportBackup", systemImage: "square.and.arrow.up")
    }
    .padding()
}
.fileImporter(
    isPresented: $isImportingBackup,
    allowedContentTypes: [.familyMemoriesBackup],
    allowsMultipleSelection: false
) { result in
    if case let .success(urls) = result, let url = urls.first {
        _ = try? environment.backupService.validateBackup(at: url)
    }
}
```

Add this conformance near app code so `URL` can be used as a sheet item:

```swift
extension URL: Identifiable {
    public var id: String { absoluteString }
}
```

- [ ] **Step 2: Add README iOS instructions**

Append to `README.md`:

```markdown
## iOS App

The native iOS app lives in `ios/FamilyMemories`.

### Requirements

- Xcode with iOS 17 SDK or newer
- An available iPhone simulator
- No server account is required for local development

### Build And Test

```bash
xcodebuild \
  -project ios/FamilyMemories/FamilyMemories.xcodeproj \
  -scheme FamilyMemories \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  test
```

### Privacy Model

The iOS app is local-first. It uses the system photo picker, copies only selected photos into app-private storage, and does not use app-owned servers or automatic cloud upload. Manual backups are created only when the user exports them.
```

- [ ] **Step 3: Run full unit and UI verification**

Run with XcodeBuildMCP `test_sim` when available. Shell fallback:

```bash
xcodebuild \
  -project ios/FamilyMemories/FamilyMemories.xcodeproj \
  -scheme FamilyMemories \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  test
```

Expected: all unit and UI tests pass.

- [ ] **Step 4: Run manual simulator verification**

Run the app:

```bash
xcodebuild \
  -project ios/FamilyMemories/FamilyMemories.xcodeproj \
  -scheme FamilyMemories \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build
```

Manual checks:

```text
1. First launch shows timeline empty state and import action.
2. Import action opens the system photo picker.
3. Imported memories appear in review.
4. Saving review creates memories in the timeline.
5. A memory opens in detail.
6. Story, date, and people edits persist after relaunch.
7. Album tab shows saved memories in page style.
8. Settings language switch changes UI copy only.
9. Export backup creates a `.familymemories` file.
10. Invalid backup import is rejected without deleting existing memories.
11. Airplane Mode does not prevent timeline, detail, album, settings, or export from working.
```

- [ ] **Step 5: Commit final iOS MVP wiring**

```bash
git add ios/FamilyMemories README.md
git commit -m "feat: complete local first ios mvp"
```

## Final Acceptance Checklist

- [ ] The iOS app exists under `ios/FamilyMemories`.
- [ ] The app builds on an iOS 17+ simulator.
- [ ] The app uses no app-owned server and no account flow.
- [ ] Multi-photo import uses the system photo picker.
- [ ] Selected photos are copied into Application Support under `FamilyMemories/Originals`.
- [ ] Thumbnails are generated under `FamilyMemories/Thumbnails`.
- [ ] SwiftData stores metadata, not original binary photos.
- [ ] Story, people, and date can be edited.
- [ ] People tags are trimmed, empty values are removed, and exact duplicates are removed.
- [ ] Timeline groups memories by year and month.
- [ ] Album reader provides a simple read-first paging experience.
- [ ] Settings includes language, privacy copy, export backup, and import backup entry points.
- [ ] Chinese/English switching changes UI copy and does not translate user-entered content.
- [ ] `.familymemories` backup validation checks manifest and memories before import.
- [ ] Full `xcodebuild ... test` passes.
- [ ] README documents the iOS build/test path and privacy model.
