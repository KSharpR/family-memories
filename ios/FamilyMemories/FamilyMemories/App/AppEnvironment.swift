import Combine
import Foundation
import SwiftData

@MainActor
final class AppEnvironment: ObservableObject {
    let fileStore: MemoryFileStore
    let repository: MemoryRepositoryProtocol
    let importService: PhotoImportService
    let backupService: BackupPackageService
    let storageUsageService: StorageUsageService
    let localDataResetService: LocalDataResetService
    let webAlbumImportService: WebAlbumImportService

    init(
        fileStore: MemoryFileStore,
        repository: MemoryRepositoryProtocol,
        importService: PhotoImportService,
        backupService: BackupPackageService,
        storageUsageService: StorageUsageService? = nil,
        localDataResetService: LocalDataResetService? = nil,
        webAlbumImportService: WebAlbumImportService? = nil
    ) {
        self.fileStore = fileStore
        self.repository = repository
        self.importService = importService
        self.backupService = backupService
        self.storageUsageService = storageUsageService ?? StorageUsageService(fileStore: fileStore)
        self.localDataResetService = localDataResetService ?? LocalDataResetService(
            repository: repository,
            fileStore: fileStore
        )
        self.webAlbumImportService = webAlbumImportService ?? WebAlbumImportService(
            fileStore: fileStore,
            repository: repository
        )
    }

    init(
        modelContext: ModelContext,
        fileManager: FileManager = .default,
        processInfo: ProcessInfo = .processInfo
    ) throws {
        let shouldResetData = processInfo.arguments.contains("-ui-testing")
            && processInfo.arguments.contains("-reset-data")

        if shouldResetData {
            try Self.resetMetadata(in: modelContext)
            let existingStore = try MemoryFileStore(fileManager: fileManager)
            try? fileManager.removeItem(at: existingStore.rootURL)
        }

        let fileStore = try MemoryFileStore(fileManager: fileManager)
        self.fileStore = fileStore
        self.repository = MemoryRepository(context: modelContext)
        self.importService = PhotoImportService(fileStore: fileStore)
        self.backupService = BackupPackageService(fileStore: fileStore)
        self.storageUsageService = StorageUsageService(fileStore: fileStore, fileManager: fileManager)
        self.localDataResetService = LocalDataResetService(repository: repository, fileStore: fileStore)
        self.webAlbumImportService = WebAlbumImportService(fileStore: fileStore, repository: repository)
    }

    private static func resetMetadata(in modelContext: ModelContext) throws {
        let records = try modelContext.fetch(FetchDescriptor<MemoryRecord>())
        for record in records {
            modelContext.delete(record)
        }
        try modelContext.save()
    }
}
