import XCTest
@testable import FamilyMemories

@MainActor
final class TimelineViewModelTests: XCTestCase {
    func testLoadsTimelineSectionsFromRepository() async throws {
        let older = Date(timeIntervalSince1970: 100)
        let newer = Date(timeIntervalSince1970: 200)
        let repository = InMemoryMemoryRepository(memories: [
            .fixture(id: "one", date: older),
            .fixture(id: "two", date: newer)
        ])

        let viewModel = TimelineViewModel(repository: repository, calendar: Calendar(identifier: .gregorian))
        await viewModel.load()

        XCTAssertEqual(viewModel.sections.map(\.id), ["1970-01"])
        XCTAssertEqual(viewModel.sections.flatMap(\.memories).map(\.id), ["two", "one"])
        XCTAssertNil(viewModel.errorMessage)
    }

    func testEmptyRepositorySetsEmptyState() async {
        let viewModel = TimelineViewModel(repository: InMemoryMemoryRepository(memories: []))
        await viewModel.load()

        XCTAssertTrue(viewModel.sections.isEmpty)
        XCTAssertTrue(viewModel.isEmpty)
    }

    func testFailedLoadSetsErrorStateWithoutEmptyState() async {
        let viewModel = TimelineViewModel(repository: FailingMemoryRepository())
        await viewModel.load()

        XCTAssertTrue(viewModel.sections.isEmpty)
        XCTAssertFalse(viewModel.isEmpty)
        XCTAssertEqual(viewModel.errorMessage, "Repository unavailable")
    }
}

private final class InMemoryMemoryRepository: MemoryRepositoryProtocol {
    var memories: [FamilyMemory]

    init(memories: [FamilyMemory]) {
        self.memories = memories
    }

    func fetchAll() async throws -> [FamilyMemory] {
        memories
    }

    func fetch(id: String) async throws -> FamilyMemory? {
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

private struct FailingMemoryRepository: MemoryRepositoryProtocol {
    func fetchAll() async throws -> [FamilyMemory] {
        throw TestRepositoryError.unavailable
    }

    func fetch(id: String) async throws -> FamilyMemory? {
        throw TestRepositoryError.unavailable
    }

    func save(_ memory: FamilyMemory) throws {
        throw TestRepositoryError.unavailable
    }

    func delete(id: String) throws {
        throw TestRepositoryError.unavailable
    }
}

private enum TestRepositoryError: LocalizedError {
    case unavailable

    var errorDescription: String? {
        "Repository unavailable"
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
