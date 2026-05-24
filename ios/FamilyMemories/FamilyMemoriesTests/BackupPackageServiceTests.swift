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
        let memory = makeMemory(paths: paths)

        let service = BackupPackageService(fileStore: store)
        let backupURL = try service.exportBackup(memories: [memory], localeIdentifier: "zh-Hans")

        XCTAssertEqual(backupURL.pathExtension, "familymemories")
        let summary = try service.validateBackup(at: backupURL)
        XCTAssertEqual(summary.memoryCount, 1)
        XCTAssertEqual(summary.localeIdentifier, "zh-Hans")
    }

    func testValidateSummaryIncludesIDsDateRangeAndSchemaVersions() throws {
        let firstPaths = try store.writeImageFiles(
            memoryID: "memory-1",
            originalFilename: "first.jpg",
            originalData: Data([1]),
            thumbnailData: Data([2])
        )
        let secondPaths = try store.writeImageFiles(
            memoryID: "memory-2",
            originalFilename: "second.jpg",
            originalData: Data([3]),
            thumbnailData: Data([4])
        )
        let firstDate = Date(timeIntervalSince1970: 100)
        let secondDate = Date(timeIntervalSince1970: 200)
        let memories = [
            makeMemory(id: "memory-1", paths: firstPaths, date: firstDate),
            makeMemory(id: "memory-2", paths: secondPaths, date: secondDate)
        ]

        let service = BackupPackageService(fileStore: store)
        let backupURL = try service.exportBackup(memories: memories, localeIdentifier: "zh-Hans")
        let summary = try service.validateBackup(at: backupURL)

        XCTAssertEqual(summary.memoryIDs, ["memory-1", "memory-2"])
        XCTAssertEqual(summary.earliestMemoryDate, firstDate)
        XCTAssertEqual(summary.latestMemoryDate, secondDate)
        XCTAssertEqual(summary.backupVersion, 1)
        XCTAssertEqual(summary.dataSchemaVersion, AppDataSchema.currentVersion)
    }

    func testExportRejectsUnsafeImagePaths() throws {
        let memory = FamilyMemory(
            id: "memory-1",
            originalFilename: "memory.jpg",
            originalPath: "../outside.jpg",
            thumbnailPath: "Thumbnails/memory-1.jpg",
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

        XCTAssertThrowsError(try service.exportBackup(memories: [memory], localeIdentifier: "zh-Hans")) { error in
            XCTAssertEqual(error as? MemoryFileStoreError, .invalidRelativePath("../outside.jpg"))
        }
    }

    func testExportFailsWhenRequiredImageFileIsMissing() throws {
        let paths = try store.writeImageFiles(
            memoryID: "memory-1",
            originalFilename: "memory.jpg",
            originalData: Data([1, 2, 3]),
            thumbnailData: Data([4, 5, 6])
        )
        try FileManager.default.removeItem(at: store.url(forRelativePath: paths.originalRelativePath))
        let memory = makeMemory(paths: paths)

        let service = BackupPackageService(fileStore: store)

        XCTAssertThrowsError(try service.exportBackup(memories: [memory], localeIdentifier: "zh-Hans")) { error in
            XCTAssertEqual(error as? BackupPackageError, .missingFile(paths.originalRelativePath))
        }
    }

    func testValidateRejectsTamperedEntryData() throws {
        let paths = try store.writeImageFiles(
            memoryID: "memory-1",
            originalFilename: "memory.jpg",
            originalData: Data([1, 2, 3]),
            thumbnailData: Data([4, 5, 6])
        )
        let service = BackupPackageService(fileStore: store)
        let backupURL = try service.exportBackup(memories: [makeMemory(paths: paths)], localeIdentifier: "zh-Hans")

        var archiveData = try Data(contentsOf: backupURL)
        guard let range = archiveData.range(of: Data([1, 2, 3])) else {
            return XCTFail("Expected backup archive to contain original image bytes")
        }
        archiveData[range.lowerBound] = 9
        try archiveData.write(to: backupURL)

        XCTAssertThrowsError(try service.validateBackup(at: backupURL)) { error in
            XCTAssertEqual(error as? BackupPackageError, .invalidArchive)
        }
    }

    func testInvalidBackupDoesNotProduceImportPayload() throws {
        let invalidURL = rootURL.appendingPathComponent("bad.familymemories")
        try Data([0]).write(to: invalidURL)

        let service = BackupPackageService(fileStore: store)

        XCTAssertThrowsError(try service.validateBackup(at: invalidURL))
    }

    func testBackupPackageErrorsDescribeUnsupportedVersionAndMissingFiles() {
        XCTAssertEqual(
            BackupPackageError.unsupportedVersion(2).errorDescription,
            "This backup uses unsupported format version 2."
        )
        XCTAssertEqual(
            BackupPackageError.missingFile("Originals/memory-1.jpg").errorDescription,
            "This backup is missing required file Originals/memory-1.jpg."
        )
    }

    func testBackupManifestDecodesVersionOneWithoutSchemaVersion() throws {
        let json = """
        {
          "appName": "Family Memories",
          "backupVersion": 1,
          "createdAt": "2026-05-24T00:00:00Z",
          "memoryCount": 0,
          "locale": "zh-Hans",
          "minimumSupportedAppVersion": "0.1.0"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let manifest = try decoder.decode(BackupManifest.self, from: json)

        XCTAssertNil(manifest.dataSchemaVersion)
        XCTAssertEqual(manifest.backupVersion, 1)
    }

    func testImportConfirmationSummaryFormatsMemoryCountAndCreationDate() {
        let summary = BackupSummary(
            memoryCount: 3,
            localeIdentifier: "zh-Hans",
            createdAt: Date(timeIntervalSince1970: 1_714_998_600),
            earliestMemoryDate: Date(timeIntervalSince1970: 100),
            latestMemoryDate: Date(timeIntervalSince1970: 200)
        )

        let formatted = BackupImportConfirmationFormatter.summaryText(
            for: summary,
            overwriteCount: 2,
            locale: Locale(identifier: "en_US"),
            timeZone: TimeZone(secondsFromGMT: 0)!
        )

        XCTAssertEqual(formatted.memoryCount, "3")
        XCTAssertEqual(formatted.overwriteCount, "2")
        XCTAssertTrue(formatted.createdAt.contains("2024"))
        XCTAssertTrue(formatted.dateRange.contains("1970"))
        XCTAssertFalse(formatted.createdAt.isEmpty)
        XCTAssertFalse(formatted.dateRange.isEmpty)
    }

    func testRestoreBackupWritesImageFilesAndReturnsMemories() throws {
        let paths = try store.writeImageFiles(
            memoryID: "memory-1",
            originalFilename: "memory.jpg",
            originalData: Data([1, 2, 3]),
            thumbnailData: Data([4, 5, 6])
        )
        let memory = makeMemory(paths: paths)
        let sourceService = BackupPackageService(fileStore: store)
        let backupURL = try sourceService.exportBackup(memories: [memory], localeIdentifier: "zh-Hans")

        let targetRootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: targetRootURL) }

        let targetStore = try MemoryFileStore(rootURL: targetRootURL)
        let targetService = BackupPackageService(fileStore: targetStore)
        let result = try targetService.restoreBackup(at: backupURL)

        XCTAssertEqual(result.summary.memoryCount, 1)
        XCTAssertEqual(result.memories, [memory])
        XCTAssertEqual(try Data(contentsOf: targetStore.url(forRelativePath: paths.originalRelativePath)), Data([1, 2, 3]))
        XCTAssertEqual(try Data(contentsOf: targetStore.url(forRelativePath: paths.thumbnailRelativePath)), Data([4, 5, 6]))
    }

    func testRestoreBackupOverwritesExistingFilesForSameMemoryID() throws {
        let paths = try store.writeImageFiles(
            memoryID: "memory-1",
            originalFilename: "memory.jpg",
            originalData: Data([1, 2, 3]),
            thumbnailData: Data([4, 5, 6])
        )
        let sourceService = BackupPackageService(fileStore: store)
        let backupURL = try sourceService.exportBackup(memories: [makeMemory(paths: paths)], localeIdentifier: "zh-Hans")

        let targetRootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: targetRootURL) }

        let targetStore = try MemoryFileStore(rootURL: targetRootURL)
        try Data([9]).write(to: targetStore.url(forRelativePath: paths.originalRelativePath), options: .atomic)
        try Data([8]).write(to: targetStore.url(forRelativePath: paths.thumbnailRelativePath), options: .atomic)

        let targetService = BackupPackageService(fileStore: targetStore)
        _ = try targetService.restoreBackup(at: backupURL)

        XCTAssertEqual(try Data(contentsOf: targetStore.url(forRelativePath: paths.originalRelativePath)), Data([1, 2, 3]))
        XCTAssertEqual(try Data(contentsOf: targetStore.url(forRelativePath: paths.thumbnailRelativePath)), Data([4, 5, 6]))
    }

    private func makeMemory(
        id: String = "memory-1",
        paths: StoredImagePaths,
        date: Date = Date(timeIntervalSince1970: 100)
    ) -> FamilyMemory {
        FamilyMemory(
            id: id,
            originalFilename: "\(id).jpg",
            originalPath: paths.originalRelativePath,
            thumbnailPath: paths.thumbnailRelativePath,
            story: "Dinner together",
            date: date,
            people: ["Mom"],
            filter: "original",
            createdAt: Date(timeIntervalSince1970: 90),
            updatedAt: Date(timeIntervalSince1970: 95),
            sourceCreatedAt: Date(timeIntervalSince1970: 80),
            sourceAssetIdentifier: nil
        )
    }
}
