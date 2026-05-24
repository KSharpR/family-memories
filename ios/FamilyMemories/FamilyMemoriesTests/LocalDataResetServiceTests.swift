import SwiftData
import XCTest
@testable import FamilyMemories

@MainActor
final class LocalDataResetServiceTests: XCTestCase {
    private var container: ModelContainer!
    private var repository: MemoryRepository!
    private var rootURL: URL!
    private var fileStore: MemoryFileStore!

    override func setUpWithError() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: MemoryRecord.self, configurations: configuration)
        repository = MemoryRepository(context: container.mainContext)
        rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        fileStore = try MemoryFileStore(rootURL: rootURL)
    }

    override func tearDownWithError() throws {
        if let rootURL {
            try? FileManager.default.removeItem(at: rootURL)
        }
    }

    func testResetRemovesRecordsAndManagedFilesThenRecreatesDirectories() async throws {
        let date = Date(timeIntervalSince1970: 1_800)
        let paths = try fileStore.writeImageFiles(
            memoryID: "reset-me",
            originalFilename: "reset-me.jpg",
            originalData: Data([1, 2, 3]),
            thumbnailData: Data([4, 5, 6])
        )
        let backupURL = fileStore.backupsDirectory.appendingPathComponent("trial.familymemories")
        try Data([7, 8, 9]).write(to: backupURL)
        let metadataURL = fileStore.rootURL.appendingPathComponent("metadata.json")
        try Data([10]).write(to: metadataURL)

        try repository.save(FamilyMemory(
            id: "reset-me",
            originalFilename: "reset-me.jpg",
            originalPath: paths.originalRelativePath,
            thumbnailPath: paths.thumbnailRelativePath,
            story: "Keep this safe in a backup first",
            date: date,
            people: ["Mom"],
            filter: "original",
            createdAt: date,
            updatedAt: date,
            sourceCreatedAt: date,
            sourceAssetIdentifier: nil
        ))

        let service = LocalDataResetService(repository: repository, fileStore: fileStore)
        let result = try await service.resetAllLocalData()

        XCTAssertEqual(result.deletedMemoryCount, 1)
        let remainingMemories = try await repository.fetchAll()
        XCTAssertTrue(remainingMemories.isEmpty)
        XCTAssertFalse(FileManager.default.fileExists(atPath: fileStore.url(forRelativePath: paths.originalRelativePath).path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: fileStore.url(forRelativePath: paths.thumbnailRelativePath).path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: backupURL.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: metadataURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileStore.originalsDirectory.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileStore.thumbnailsDirectory.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileStore.backupsDirectory.path))

        let usage = try StorageUsageService(fileStore: fileStore).calculateUsage()
        XCTAssertEqual(usage.totalBytes, 0)
    }
}
