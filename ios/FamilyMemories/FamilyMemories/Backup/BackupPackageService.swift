import Foundation

enum BackupPackageError: LocalizedError, Equatable {
    case invalidArchive
    case missingManifest
    case missingMemories
    case missingFile(String)
    case unsupportedVersion(Int)

    var errorDescription: String? {
        switch self {
        case .invalidArchive:
            return "This backup file is damaged or not a Family Memories backup."
        case .missingManifest:
            return "This backup is missing manifest.json."
        case .missingMemories:
            return "This backup is missing memories.json."
        case let .missingFile(path):
            return "This backup is missing required file \(path)."
        case let .unsupportedVersion(version):
            return "This backup uses unsupported format version \(version)."
        }
    }
}

final class BackupPackageService {
    private let fileStore: MemoryFileStore
    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(fileStore: MemoryFileStore, fileManager: FileManager = .default) {
        self.fileStore = fileStore
        self.fileManager = fileManager

        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    func exportBackup(memories: [FamilyMemory], localeIdentifier: String) throws -> URL {
        let filename = "family-memories-\(Self.timestamp())-\(UUID().uuidString).familymemories"
        let archiveURL = fileStore.backupsDirectory.appendingPathComponent(filename)
        if fileManager.fileExists(atPath: archiveURL.path) {
            try fileManager.removeItem(at: archiveURL)
        }

        let manifest = BackupManifest(
            appName: "Family Memories",
            backupVersion: 1,
            dataSchemaVersion: AppDataSchema.currentVersion,
            createdAt: Date(),
            memoryCount: memories.count,
            locale: localeIdentifier,
            minimumSupportedAppVersion: "0.1.0"
        )

        var entries: [StoredZipEntry] = [
            StoredZipEntry(path: "manifest.json", data: try encoder.encode(manifest)),
            StoredZipEntry(path: "memories.json", data: try encoder.encode(memories.map(BackupMemoryDTO.init(memory:))))
        ]

        for memory in memories {
            entries.append(StoredZipEntry(
                path: memory.originalPath,
                data: try dataForRequiredFile(relativePath: memory.originalPath, expectedDirectory: "Originals")
            ))
            entries.append(StoredZipEntry(
                path: memory.thumbnailPath,
                data: try dataForRequiredFile(relativePath: memory.thumbnailPath, expectedDirectory: "Thumbnails")
            ))
        }

        try StoredZipArchive.write(entries: entries, to: archiveURL)
        return archiveURL
    }

    func validateBackup(at url: URL) throws -> BackupSummary {
        try readValidBackup(from: url).summary
    }

    func restoreBackup(at url: URL) throws -> BackupRestoreResult {
        let backup = try readValidBackup(from: url)

        for memory in backup.memories {
            try restoreFile(
                relativePath: memory.originalPath,
                expectedDirectory: "Originals",
                entries: backup.entries
            )
            try restoreFile(
                relativePath: memory.thumbnailPath,
                expectedDirectory: "Thumbnails",
                entries: backup.entries
            )
        }

        return BackupRestoreResult(
            summary: backup.summary,
            memories: backup.memories.map(\.domain)
        )
    }

    private func readValidBackup(from url: URL) throws -> ParsedBackup {
        let entries = try StoredZipArchive.readEntries(from: url)
        guard let manifestData = entries["manifest.json"] else {
            throw BackupPackageError.missingManifest
        }
        guard let memoriesData = entries["memories.json"] else {
            throw BackupPackageError.missingMemories
        }

        let manifest = try decoder.decode(BackupManifest.self, from: manifestData)
        guard manifest.backupVersion == 1 else {
            throw BackupPackageError.unsupportedVersion(manifest.backupVersion)
        }

        let memories = try decoder.decode([BackupMemoryDTO].self, from: memoriesData)
        guard memories.count == manifest.memoryCount else {
            throw BackupPackageError.invalidArchive
        }
        guard Set(memories.map(\.id)).count == memories.count else {
            throw BackupPackageError.invalidArchive
        }
        for memory in memories {
            try validateRelativePath(memory.originalPath, expectedDirectory: "Originals")
            try validateRelativePath(memory.thumbnailPath, expectedDirectory: "Thumbnails")
            guard entries[memory.originalPath] != nil else {
                throw BackupPackageError.missingFile(memory.originalPath)
            }
            guard entries[memory.thumbnailPath] != nil else {
                throw BackupPackageError.missingFile(memory.thumbnailPath)
            }
        }

        let summary = BackupSummary(
            memoryCount: manifest.memoryCount,
            localeIdentifier: manifest.locale,
            createdAt: manifest.createdAt,
            memoryIDs: memories.map(\.id),
            earliestMemoryDate: memories.map(\.date).min(),
            latestMemoryDate: memories.map(\.date).max(),
            backupVersion: manifest.backupVersion,
            dataSchemaVersion: manifest.dataSchemaVersion ?? 1
        )

        return ParsedBackup(
            summary: summary,
            memories: memories,
            entries: entries
        )
    }

    private func restoreFile(
        relativePath: String,
        expectedDirectory: String,
        entries: [String: Data]
    ) throws {
        try validateRelativePath(relativePath, expectedDirectory: expectedDirectory)
        guard let data = entries[relativePath] else {
            throw BackupPackageError.missingFile(relativePath)
        }
        try data.write(to: fileStore.url(forRelativePath: relativePath), options: .atomic)
    }

    private func dataForRequiredFile(relativePath: String, expectedDirectory: String) throws -> Data {
        try validateRelativePath(relativePath, expectedDirectory: expectedDirectory)
        let url = fileStore.url(forRelativePath: relativePath)
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory), isDirectory.boolValue == false else {
            throw BackupPackageError.missingFile(relativePath)
        }
        return try Data(contentsOf: url)
    }

    private func validateRelativePath(_ path: String, expectedDirectory: String) throws {
        let components = path.split(separator: "/", omittingEmptySubsequences: false).map(String.init)
        let fileName = components.last ?? ""
        guard
            path.isEmpty == false,
            path.contains("..") == false,
            path.hasPrefix("/") == false,
            components.count == 2,
            components.first == expectedDirectory,
            fileName.isEmpty == false,
            URL(fileURLWithPath: fileName).pathExtension.isEmpty == false
        else {
            throw MemoryFileStoreError.invalidRelativePath(path)
        }
    }

    private static func timestamp() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: Date()).replacingOccurrences(of: ":", with: "-")
    }
}

private struct ParsedBackup {
    let summary: BackupSummary
    let memories: [BackupMemoryDTO]
    let entries: [String: Data]
}

private struct StoredZipEntry {
    let path: String
    let data: Data
}

private enum StoredZipArchive {
    private static let localFileHeaderSignature: UInt32 = 0x04034b50
    private static let centralDirectorySignature: UInt32 = 0x02014b50
    private static let endOfCentralDirectorySignature: UInt32 = 0x06054b50

    static func write(entries: [StoredZipEntry], to url: URL) throws {
        var output = Data()
        var centralDirectory = Data()

        for entry in entries {
            guard let filenameData = entry.path.data(using: .utf8) else {
                throw BackupPackageError.invalidArchive
            }
            guard
                let filenameLength = UInt16(exactly: filenameData.count),
                let entryDataLength = UInt32(exactly: entry.data.count),
                let localHeaderOffset = UInt32(exactly: output.count)
            else {
                throw BackupPackageError.invalidArchive
            }

            let checksum = CRC32.checksum(entry.data)

            output.appendUInt32(localFileHeaderSignature)
            output.appendUInt16(20)
            output.appendUInt16(0)
            output.appendUInt16(0)
            output.appendUInt16(0)
            output.appendUInt16(0)
            output.appendUInt32(checksum)
            output.appendUInt32(entryDataLength)
            output.appendUInt32(entryDataLength)
            output.appendUInt16(filenameLength)
            output.appendUInt16(0)
            output.append(filenameData)
            output.append(entry.data)

            centralDirectory.appendUInt32(centralDirectorySignature)
            centralDirectory.appendUInt16(20)
            centralDirectory.appendUInt16(20)
            centralDirectory.appendUInt16(0)
            centralDirectory.appendUInt16(0)
            centralDirectory.appendUInt16(0)
            centralDirectory.appendUInt16(0)
            centralDirectory.appendUInt32(checksum)
            centralDirectory.appendUInt32(entryDataLength)
            centralDirectory.appendUInt32(entryDataLength)
            centralDirectory.appendUInt16(filenameLength)
            centralDirectory.appendUInt16(0)
            centralDirectory.appendUInt16(0)
            centralDirectory.appendUInt16(0)
            centralDirectory.appendUInt16(0)
            centralDirectory.appendUInt32(0)
            centralDirectory.appendUInt32(localHeaderOffset)
            centralDirectory.append(filenameData)
        }

        guard
            let centralDirectoryOffset = UInt32(exactly: output.count),
            let centralDirectoryLength = UInt32(exactly: centralDirectory.count),
            let entryCount = UInt16(exactly: entries.count)
        else {
            throw BackupPackageError.invalidArchive
        }

        output.append(centralDirectory)
        output.appendUInt32(endOfCentralDirectorySignature)
        output.appendUInt16(0)
        output.appendUInt16(0)
        output.appendUInt16(entryCount)
        output.appendUInt16(entryCount)
        output.appendUInt32(centralDirectoryLength)
        output.appendUInt32(centralDirectoryOffset)
        output.appendUInt16(0)

        try output.write(to: url, options: .atomic)
    }

    static func readEntries(from url: URL) throws -> [String: Data] {
        let data = try Data(contentsOf: url)
        guard let endOffset = data.lastOffset(ofLittleEndianUInt32: endOfCentralDirectorySignature) else {
            throw BackupPackageError.invalidArchive
        }

        let entryCount = Int(try data.uint16(at: endOffset + 10))
        let centralDirectoryOffset = Int(try data.uint32(at: endOffset + 16))
        var cursor = centralDirectoryOffset
        var entries: [String: Data] = [:]

        for _ in 0..<entryCount {
            guard try data.uint32(at: cursor) == centralDirectorySignature else {
                throw BackupPackageError.invalidArchive
            }

            let compressionMethod = try data.uint16(at: cursor + 10)
            guard compressionMethod == 0 else {
                throw BackupPackageError.invalidArchive
            }

            let expectedChecksum = try data.uint32(at: cursor + 16)
            let compressedSize = Int(try data.uint32(at: cursor + 20))
            let filenameLength = Int(try data.uint16(at: cursor + 28))
            let extraFieldLength = Int(try data.uint16(at: cursor + 30))
            let fileCommentLength = Int(try data.uint16(at: cursor + 32))
            let localHeaderOffset = Int(try data.uint32(at: cursor + 42))
            let filenameStart = cursor + 46
            let filenameEnd = filenameStart + filenameLength
            guard filenameEnd <= data.count else {
                throw BackupPackageError.invalidArchive
            }

            let filenameData = data.subdata(in: filenameStart..<filenameEnd)
            guard let filename = String(data: filenameData, encoding: .utf8) else {
                throw BackupPackageError.invalidArchive
            }

            guard try data.uint32(at: localHeaderOffset) == localFileHeaderSignature else {
                throw BackupPackageError.invalidArchive
            }
            guard try data.uint16(at: localHeaderOffset + 8) == 0 else {
                throw BackupPackageError.invalidArchive
            }
            guard try data.uint32(at: localHeaderOffset + 14) == expectedChecksum else {
                throw BackupPackageError.invalidArchive
            }
            guard Int(try data.uint32(at: localHeaderOffset + 18)) == compressedSize else {
                throw BackupPackageError.invalidArchive
            }

            let localFilenameLength = Int(try data.uint16(at: localHeaderOffset + 26))
            let localExtraFieldLength = Int(try data.uint16(at: localHeaderOffset + 28))
            let localFilenameStart = localHeaderOffset + 30
            let localFilenameEnd = localFilenameStart + localFilenameLength
            guard localFilenameEnd <= data.count else {
                throw BackupPackageError.invalidArchive
            }
            guard data.subdata(in: localFilenameStart..<localFilenameEnd) == filenameData else {
                throw BackupPackageError.invalidArchive
            }

            let fileDataStart = localFilenameEnd + localExtraFieldLength
            let fileDataEnd = fileDataStart + compressedSize
            guard fileDataEnd <= data.count else {
                throw BackupPackageError.invalidArchive
            }

            let fileData = data.subdata(in: fileDataStart..<fileDataEnd)
            guard CRC32.checksum(fileData) == expectedChecksum else {
                throw BackupPackageError.invalidArchive
            }
            guard entries[filename] == nil else {
                throw BackupPackageError.invalidArchive
            }
            entries[filename] = fileData
            cursor = filenameEnd + extraFieldLength + fileCommentLength
        }

        return entries
    }
}

private enum CRC32 {
    private static let table: [UInt32] = (0..<256).map { value in
        var checksum = UInt32(value)
        for _ in 0..<8 {
            if checksum & 1 == 1 {
                checksum = 0xedb88320 ^ (checksum >> 1)
            } else {
                checksum >>= 1
            }
        }
        return checksum
    }

    static func checksum(_ data: Data) -> UInt32 {
        var checksum: UInt32 = 0xffffffff
        for byte in data {
            let index = Int((checksum ^ UInt32(byte)) & 0xff)
            checksum = table[index] ^ (checksum >> 8)
        }
        return checksum ^ 0xffffffff
    }
}

private extension Data {
    mutating func appendUInt16(_ value: UInt16) {
        append(contentsOf: Swift.withUnsafeBytes(of: value.littleEndian, Array.init))
    }

    mutating func appendUInt32(_ value: UInt32) {
        append(contentsOf: Swift.withUnsafeBytes(of: value.littleEndian, Array.init))
    }

    func uint16(at offset: Int) throws -> UInt16 {
        guard offset >= 0, offset + 2 <= count else {
            throw BackupPackageError.invalidArchive
        }
        return self[offset..<offset + 2].withUnsafeBytes { $0.loadUnaligned(as: UInt16.self) }.littleEndian
    }

    func uint32(at offset: Int) throws -> UInt32 {
        guard offset >= 0, offset + 4 <= count else {
            throw BackupPackageError.invalidArchive
        }
        return self[offset..<offset + 4].withUnsafeBytes { $0.loadUnaligned(as: UInt32.self) }.littleEndian
    }

    func lastOffset(ofLittleEndianUInt32 signature: UInt32) -> Int? {
        guard count >= 4 else { return nil }
        let bytes = Swift.withUnsafeBytes(of: signature.littleEndian, Array.init)

        for index in stride(from: count - 4, through: 0, by: -1) {
            if self[index..<index + 4].elementsEqual(bytes) {
                return index
            }
        }
        return nil
    }
}
