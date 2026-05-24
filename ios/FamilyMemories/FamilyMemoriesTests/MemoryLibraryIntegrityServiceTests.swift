import SwiftData
import XCTest
@testable import FamilyMemories

@MainActor
final class MemoryLibraryIntegrityServiceTests: XCTestCase {
    private var rootURL: URL!
    private var store: MemoryFileStore!
    private var container: ModelContainer!
    private var repository: MemoryRepository!

    override func setUpWithError() throws {
        rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        store = try MemoryFileStore(rootURL: rootURL)
        container = try ModelContainer(
            for: MemoryRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        repository = MemoryRepository(context: container.mainContext)
    }

    override func tearDownWithError() throws {
        if let rootURL {
            try? FileManager.default.removeItem(at: rootURL)
        }
    }

    func testFindsAndRemovesMemoriesWithMissingImageFiles() async throws {
        let validPaths = try store.writeImageFiles(
            memoryID: "valid",
            originalFilename: "valid.jpg",
            originalData: Data([1]),
            thumbnailData: Data([2])
        )
        try repository.save(FamilyMemory.fixture(id: "valid", paths: validPaths))

        let missingPaths = StoredImagePaths(
            originalRelativePath: "Originals/missing.jpg",
            thumbnailRelativePath: "Thumbnails/missing.jpg"
        )
        try repository.save(FamilyMemory.fixture(id: "missing", paths: missingPaths))

        let service = MemoryLibraryIntegrityService(repository: repository, fileStore: store)
        let issues = try await service.missingFileIssues()

        XCTAssertEqual(issues.map(\.memoryID), ["missing"])
        XCTAssertTrue(issues[0].isOriginalMissing)
        XCTAssertTrue(issues[0].isThumbnailMissing)

        let removedIDs = try await service.removeMemoriesWithMissingFiles()
        let validMemory = try await repository.fetch(id: "valid")
        let missingMemory = try await repository.fetch(id: "missing")

        XCTAssertEqual(removedIDs, ["missing"])
        XCTAssertNotNil(validMemory)
        XCTAssertNil(missingMemory)
    }
}

private extension FamilyMemory {
    static func fixture(id: String, paths: StoredImagePaths) -> FamilyMemory {
        let date = Date(timeIntervalSince1970: 100)
        return FamilyMemory(
            id: id,
            originalFilename: "\(id).jpg",
            originalPath: paths.originalRelativePath,
            thumbnailPath: paths.thumbnailRelativePath,
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
