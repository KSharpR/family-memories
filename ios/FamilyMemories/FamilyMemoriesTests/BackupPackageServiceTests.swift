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

    private func makeMemory(paths: StoredImagePaths) -> FamilyMemory {
        FamilyMemory(
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
    }
}
