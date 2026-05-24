import SwiftData
import XCTest
@testable import FamilyMemories

@MainActor
final class WebAlbumImportServiceTests: XCTestCase {
    private var container: ModelContainer!
    private var repository: MemoryRepository!
    private var rootURL: URL!
    private var fileStore: MemoryFileStore!

    override func setUpWithError() throws {
        container = try ModelContainer(
            for: MemoryRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
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

    func testImportsWebAlbumCandidatesIntoLocalLibrary() async throws {
        let json = """
        {
          "memories": [
            {
              "id": "web-1",
              "photoDataUrl": "data:image/png;base64,AQID",
              "story": "一起包饺子的下午",
              "date": "2026-05-20",
              "people": ["奶奶", "我"],
              "filter": "none",
              "createdAt": "2026-05-01T12:00:00.000Z",
              "updatedAt": "2026-05-02T13:30:00.000Z"
            }
          ]
        }
        """.data(using: .utf8)!
        let service = WebAlbumImportService(
            fileStore: fileStore,
            repository: repository,
            thumbnailGenerator: { _ in Data([9, 8, 7]) }
        )

        let result = try await service.importAlbumJSON(json)

        XCTAssertEqual(result.importedCount, 1)
        let fetched = try await repository.fetch(id: "web-1")
        let saved = try XCTUnwrap(fetched)
        XCTAssertEqual(saved.story, "一起包饺子的下午")
        XCTAssertEqual(saved.date, Date(timeIntervalSince1970: 1_779_235_200))
        XCTAssertEqual(saved.people, ["奶奶", "我"])
        XCTAssertEqual(saved.filter, "original")
        XCTAssertEqual(saved.originalFilename, "web-1.png")
        XCTAssertEqual(saved.originalPath, "Originals/web-1.png")
        XCTAssertEqual(saved.thumbnailPath, "Thumbnails/web-1.jpg")
        XCTAssertNil(saved.sourceCreatedAt)
        XCTAssertNil(saved.sourceAssetIdentifier)
        XCTAssertEqual(try Data(contentsOf: fileStore.url(forRelativePath: saved.originalPath)), Data([1, 2, 3]))
        XCTAssertEqual(try Data(contentsOf: fileStore.url(forRelativePath: saved.thumbnailPath)), Data([9, 8, 7]))
    }
}
