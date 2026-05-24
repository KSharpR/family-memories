import XCTest
@testable import FamilyMemories

final class StorageUsageServiceTests: XCTestCase {
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

    func testCalculatesStorageUsageByManagedDirectory() throws {
        try Data([1, 2, 3]).write(to: store.originalsDirectory.appendingPathComponent("one.jpg"))
        try Data([4, 5]).write(to: store.thumbnailsDirectory.appendingPathComponent("one.jpg"))
        try Data([6, 7, 8, 9]).write(to: store.backupsDirectory.appendingPathComponent("backup.familymemories"))
        try Data([10, 11, 12, 13, 14]).write(to: store.rootURL.appendingPathComponent("metadata.sqlite"))

        let usage = try StorageUsageService(fileStore: store).calculateUsage()

        XCTAssertEqual(usage.originalsBytes, 3)
        XCTAssertEqual(usage.thumbnailsBytes, 2)
        XCTAssertEqual(usage.backupsBytes, 4)
        XCTAssertEqual(usage.metadataBytes, 5)
        XCTAssertEqual(usage.totalBytes, 14)
    }
}
