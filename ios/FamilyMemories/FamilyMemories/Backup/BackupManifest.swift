import Foundation

struct BackupManifest: Codable, Equatable {
    let appName: String
    let backupVersion: Int
    let dataSchemaVersion: Int?
    let createdAt: Date
    let memoryCount: Int
    let locale: String
    let minimumSupportedAppVersion: String
}

struct BackupSummary: Equatable {
    let memoryCount: Int
    let localeIdentifier: String
    let createdAt: Date
    let memoryIDs: [String]
    let earliestMemoryDate: Date?
    let latestMemoryDate: Date?
    let backupVersion: Int
    let dataSchemaVersion: Int

    init(
        memoryCount: Int,
        localeIdentifier: String,
        createdAt: Date,
        memoryIDs: [String] = [],
        earliestMemoryDate: Date? = nil,
        latestMemoryDate: Date? = nil,
        backupVersion: Int = 1,
        dataSchemaVersion: Int = AppDataSchema.currentVersion
    ) {
        self.memoryCount = memoryCount
        self.localeIdentifier = localeIdentifier
        self.createdAt = createdAt
        self.memoryIDs = memoryIDs
        self.earliestMemoryDate = earliestMemoryDate
        self.latestMemoryDate = latestMemoryDate
        self.backupVersion = backupVersion
        self.dataSchemaVersion = dataSchemaVersion
    }
}

struct BackupRestoreResult: Equatable {
    let summary: BackupSummary
    let memories: [FamilyMemory]
}
