import Foundation

struct StoredImagePaths: Equatable {
    let originalRelativePath: String
    let thumbnailRelativePath: String
}

enum MemoryFileStoreError: Error, Equatable {
    case invalidRelativePath(String)
}

final class MemoryFileStore {
    let rootURL: URL
    let originalsDirectory: URL
    let thumbnailsDirectory: URL
    let backupsDirectory: URL

    private let fileManager: FileManager

    init(rootURL: URL? = nil, fileManager: FileManager = .default) throws {
        self.fileManager = fileManager

        let resolvedRoot: URL
        if let rootURL {
            resolvedRoot = rootURL
        } else {
            resolvedRoot = try fileManager
                .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("FamilyMemories", isDirectory: true)
        }

        self.rootURL = resolvedRoot
        self.originalsDirectory = resolvedRoot.appendingPathComponent("Originals", isDirectory: true)
        self.thumbnailsDirectory = resolvedRoot.appendingPathComponent("Thumbnails", isDirectory: true)
        self.backupsDirectory = resolvedRoot.appendingPathComponent("Backups", isDirectory: true)

        try fileManager.createDirectory(at: originalsDirectory, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: thumbnailsDirectory, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: backupsDirectory, withIntermediateDirectories: true)
    }

    func writeImageFiles(
        memoryID: String,
        originalFilename: String,
        originalData: Data,
        thumbnailData: Data
    ) throws -> StoredImagePaths {
        let fileExtension = normalizedExtension(from: originalFilename)
        let originalRelativePath = "Originals/\(memoryID).\(fileExtension)"
        let thumbnailRelativePath = "Thumbnails/\(memoryID).jpg"

        try originalData.write(to: url(forRelativePath: originalRelativePath), options: .atomic)
        try thumbnailData.write(to: url(forRelativePath: thumbnailRelativePath), options: .atomic)

        return StoredImagePaths(
            originalRelativePath: originalRelativePath,
            thumbnailRelativePath: thumbnailRelativePath
        )
    }

    func url(forRelativePath relativePath: String) -> URL {
        rootURL.appendingPathComponent(relativePath, isDirectory: false)
    }

    func deleteMemoryFiles(originalRelativePath: String, thumbnailRelativePath: String) throws {
        let paths = [originalRelativePath, thumbnailRelativePath]
        for path in paths {
            try validateRelativePath(path)
        }

        for path in paths {
            let url = url(forRelativePath: path)
            if fileManager.fileExists(atPath: url.path) {
                try fileManager.removeItem(at: url)
            }
        }
    }

    private func validateRelativePath(_ path: String) throws {
        guard path.contains("..") == false, path.hasPrefix("/") == false else {
            throw MemoryFileStoreError.invalidRelativePath(path)
        }
    }

    private func normalizedExtension(from filename: String) -> String {
        let ext = URL(fileURLWithPath: filename).pathExtension.lowercased()
        if ["jpg", "jpeg", "png", "heic", "heif"].contains(ext) {
            return ext == "jpeg" ? "jpg" : ext
        }
        return "jpg"
    }
}
