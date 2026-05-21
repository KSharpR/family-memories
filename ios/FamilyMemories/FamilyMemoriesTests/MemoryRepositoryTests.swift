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
        memory.people = [" Mom ", "Dad", "Mom"]
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
