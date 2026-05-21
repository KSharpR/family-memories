import Combine
import Foundation
import SwiftData

@MainActor
final class AppEnvironment: ObservableObject {
    let fileStore: MemoryFileStore
    let repository: MemoryRepository
    let importService: PhotoImportService

    init(modelContext: ModelContext) throws {
        let fileStore = try MemoryFileStore()
        self.fileStore = fileStore
        self.repository = MemoryRepository(context: modelContext)
        self.importService = PhotoImportService(fileStore: fileStore)
    }
}
