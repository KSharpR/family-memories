import Foundation

struct WebAlbumImportResult: Equatable {
    let importedCount: Int
}

struct WebAlbumImportSummary: Equatable {
    let memoryCount: Int
    let overwriteCount: Int
    let earliestMemoryDate: Date?
    let latestMemoryDate: Date?
}

@MainActor
final class WebAlbumImportService {
    private let adapter: WebAlbumImportAdapter
    private let fileStore: MemoryFileStore
    private let repository: MemoryRepositoryProtocol
    private let thumbnailGenerator: (Data) throws -> Data

    init(
        adapter: WebAlbumImportAdapter = WebAlbumImportAdapter(),
        fileStore: MemoryFileStore,
        repository: MemoryRepositoryProtocol,
        thumbnailGenerator: @escaping (Data) throws -> Data = PhotoImportService.makeThumbnailJPEGData
    ) {
        self.adapter = adapter
        self.fileStore = fileStore
        self.repository = repository
        self.thumbnailGenerator = thumbnailGenerator
    }

    /// Parses the web album JSON and returns a read-only preview summary
    /// without writing files, generating thumbnails, or saving to the repository.
    func previewAlbumJSON(_ data: Data, existingMemoryIDs: Set<String>) throws -> WebAlbumImportSummary {
        let candidates = try adapter.importCandidates(from: data)

        let candidateIDs = Set(candidates.map(\.id))
        let overwriteCount = candidateIDs.intersection(existingMemoryIDs).count

        let dates = candidates.map(\.date)
        let earliestMemoryDate = dates.min()
        let latestMemoryDate = dates.max()

        return WebAlbumImportSummary(
            memoryCount: candidates.count,
            overwriteCount: overwriteCount,
            earliestMemoryDate: earliestMemoryDate,
            latestMemoryDate: latestMemoryDate
        )
    }

    func importAlbumJSON(_ data: Data) async throws -> WebAlbumImportResult {
        let candidates = try adapter.importCandidates(from: data)

        for candidate in candidates {
            let thumbnailData = try thumbnailGenerator(candidate.originalData)
            let paths = try fileStore.writeImageFiles(
                memoryID: candidate.id,
                originalFilename: candidate.originalFilename,
                originalData: candidate.originalData,
                thumbnailData: thumbnailData
            )
            let memory = FamilyMemory(
                id: candidate.id,
                originalFilename: candidate.originalFilename,
                originalPath: paths.originalRelativePath,
                thumbnailPath: paths.thumbnailRelativePath,
                story: candidate.story,
                date: candidate.date,
                people: candidate.people,
                filter: candidate.filter,
                createdAt: candidate.createdAt,
                updatedAt: candidate.updatedAt,
                sourceCreatedAt: nil,
                sourceAssetIdentifier: nil
            )
            try repository.save(memory)
        }

        return WebAlbumImportResult(importedCount: candidates.count)
    }
}
