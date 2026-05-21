import Combine
import Foundation
import SwiftData

@MainActor
final class AppEnvironment: ObservableObject {
    let fileStore: MemoryFileStore
    let repository: MemoryRepositoryProtocol
    let importService: PhotoImportService

    init(
        fileStore: MemoryFileStore,
        repository: MemoryRepositoryProtocol,
        importService: PhotoImportService
    ) {
        self.fileStore = fileStore
        self.repository = repository
        self.importService = importService
    }

    init(
        modelContext: ModelContext,
        fileManager: FileManager = .default,
        processInfo: ProcessInfo = .processInfo
    ) throws {
        let shouldResetData = processInfo.arguments.contains("-ui-testing")
            && processInfo.arguments.contains("-reset-data")

        if shouldResetData {
            let existingStore = try MemoryFileStore(fileManager: fileManager)
            try? fileManager.removeItem(at: existingStore.rootURL)
            try Self.resetMetadata(in: modelContext)
        }

        let fileStore = try MemoryFileStore(fileManager: fileManager)
        self.fileStore = fileStore
        self.repository = MemoryRepository(context: modelContext)
        self.importService = PhotoImportService(fileStore: fileStore)
    }

    private static func resetMetadata(in modelContext: ModelContext) throws {
        let records = try modelContext.fetch(FetchDescriptor<MemoryRecord>())
        for record in records {
            modelContext.delete(record)
        }
        try modelContext.save()
    }
}
