import Foundation

struct LocalDataResetResult: Equatable {
    let deletedMemoryCount: Int
}

@MainActor
final class LocalDataResetService {
    private let repository: MemoryRepositoryProtocol
    private let fileStore: MemoryFileStore

    init(repository: MemoryRepositoryProtocol, fileStore: MemoryFileStore) {
        self.repository = repository
        self.fileStore = fileStore
    }

    func resetAllLocalData() async throws -> LocalDataResetResult {
        let memories = try await repository.fetchAll()

        for memory in memories {
            try repository.delete(id: memory.id)
        }

        try fileStore.removeAllManagedData()

        return LocalDataResetResult(deletedMemoryCount: memories.count)
    }
}
