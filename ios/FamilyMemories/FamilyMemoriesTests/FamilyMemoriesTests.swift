import XCTest
@testable import FamilyMemories

final class FamilyMemoriesTests: XCTestCase {
    func testAppRootViewCanBeConstructed() {
        _ = AppRootView()
    }

    @MainActor
    func testAppEnvironmentExposesBackupService() throws {
        let rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: rootURL) }

        let fileStore = try MemoryFileStore(rootURL: rootURL)
        let environment = AppEnvironment(
            fileStore: fileStore,
            repository: EmptyMemoryRepository(),
            importService: PhotoImportService(fileStore: fileStore),
            backupService: BackupPackageService(fileStore: fileStore)
        )

        XCTAssertNotNil(environment.backupService)
    }
}

@MainActor
private struct EmptyMemoryRepository: MemoryRepositoryProtocol {
    func fetchAll() async throws -> [FamilyMemory] {
        []
    }

    func fetch(id: String) async throws -> FamilyMemory? {
        nil
    }

    func save(_ memory: FamilyMemory) throws {}

    func delete(id: String) throws {}
}
