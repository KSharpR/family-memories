import Foundation

struct MemoryLibraryIntegrityIssue: Equatable {
    let memoryID: String
    let isOriginalMissing: Bool
    let isThumbnailMissing: Bool

    var hasMissingFiles: Bool {
        isOriginalMissing || isThumbnailMissing
    }
}

@MainActor
final class MemoryLibraryIntegrityService {
    private let repository: MemoryRepositoryProtocol
    private let fileStore: MemoryFileStore
    private let fileManager: FileManager

    init(
        repository: MemoryRepositoryProtocol,
        fileStore: MemoryFileStore,
        fileManager: FileManager = .default
    ) {
        self.repository = repository
        self.fileStore = fileStore
        self.fileManager = fileManager
    }

    func missingFileIssues() async throws -> [MemoryLibraryIntegrityIssue] {
        let memories = try await repository.fetchAll()
        return memories.compactMap { memory in
            let originalMissing = isRegularFileMissing(at: fileStore.url(forRelativePath: memory.originalPath))
            let thumbnailMissing = isRegularFileMissing(at: fileStore.url(forRelativePath: memory.thumbnailPath))
            let issue = MemoryLibraryIntegrityIssue(
                memoryID: memory.id,
                isOriginalMissing: originalMissing,
                isThumbnailMissing: thumbnailMissing
            )
            return issue.hasMissingFiles ? issue : nil
        }
    }

    @discardableResult
    func removeMemoriesWithMissingFiles() async throws -> [String] {
        let issues = try await missingFileIssues()
        for issue in issues {
            try repository.delete(id: issue.memoryID)
        }
        return issues.map(\.memoryID)
    }

    private func isRegularFileMissing(at url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        let exists = fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory)
        return exists == false || isDirectory.boolValue
    }
}
