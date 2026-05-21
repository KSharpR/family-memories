import Foundation

struct BackupManifest: Codable, Equatable {
    let appName: String
    let backupVersion: Int
    let createdAt: Date
    let memoryCount: Int
    let locale: String
    let minimumSupportedAppVersion: String
}

struct BackupSummary: Equatable {
    let memoryCount: Int
    let localeIdentifier: String
    let createdAt: Date
}
