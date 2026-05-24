import Foundation

struct StorageUsage: Equatable {
    let originalsBytes: Int64
    let thumbnailsBytes: Int64
    let backupsBytes: Int64
    let metadataBytes: Int64

    var totalBytes: Int64 {
        originalsBytes + thumbnailsBytes + backupsBytes + metadataBytes
    }
}

final class StorageUsageService {
    private let fileStore: MemoryFileStore
    private let fileManager: FileManager

    init(fileStore: MemoryFileStore, fileManager: FileManager = .default) {
        self.fileStore = fileStore
        self.fileManager = fileManager
    }

    func calculateUsage() throws -> StorageUsage {
        StorageUsage(
            originalsBytes: try byteCount(in: fileStore.originalsDirectory),
            thumbnailsBytes: try byteCount(in: fileStore.thumbnailsDirectory),
            backupsBytes: try byteCount(in: fileStore.backupsDirectory),
            metadataBytes: try metadataByteCount()
        )
    }

    private func metadataByteCount() throws -> Int64 {
        let managedDirectoryPaths = Set([
            fileStore.originalsDirectory.standardizedFileURL.path,
            fileStore.thumbnailsDirectory.standardizedFileURL.path,
            fileStore.backupsDirectory.standardizedFileURL.path
        ])

        let rootContents = try fileManager.contentsOfDirectory(
            at: fileStore.rootURL,
            includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey],
            options: [.skipsHiddenFiles]
        )

        return try rootContents.reduce(Int64(0)) { total, url in
            if managedDirectoryPaths.contains(url.standardizedFileURL.path) {
                return total
            }

            return total + (try byteCount(at: url))
        }
    }

    private func byteCount(in directory: URL) throws -> Int64 {
        guard let enumerator = fileManager.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else {
            return 0
        }

        var total = Int64(0)
        for case let fileURL as URL in enumerator {
            total += try regularFileByteCount(at: fileURL)
        }
        return total
    }

    private func byteCount(at url: URL) throws -> Int64 {
        let resourceValues = try url.resourceValues(forKeys: [.isDirectoryKey])
        if resourceValues.isDirectory == true {
            return try byteCount(in: url)
        }
        return try regularFileByteCount(at: url)
    }

    private func regularFileByteCount(at url: URL) throws -> Int64 {
        let resourceValues = try url.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey])
        guard resourceValues.isRegularFile == true else {
            return 0
        }
        return Int64(resourceValues.fileSize ?? 0)
    }
}
