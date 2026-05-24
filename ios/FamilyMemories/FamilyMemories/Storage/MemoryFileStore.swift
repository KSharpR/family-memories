import Foundation

struct StoredImagePaths: Equatable {
    let originalRelativePath: String
    let thumbnailRelativePath: String
}

enum MemoryFileStoreError: Error, Equatable {
    case invalidRelativePath(String)
    case invalidMemoryID(String)
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

        try createManagedDirectories()
    }

    func removeAllManagedData() throws {
        if fileManager.fileExists(atPath: rootURL.path) {
            try fileManager.removeItem(at: rootURL)
        }

        try createManagedDirectories()
    }

    private func createManagedDirectories() throws {
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
        try validateMemoryID(memoryID)

        let fileExtension = normalizedExtension(from: originalFilename)
        let originalRelativePath = "Originals/\(memoryID).\(fileExtension)"
        let thumbnailRelativePath = "Thumbnails/\(memoryID).jpg"
        let originalURL = url(forRelativePath: originalRelativePath)
        let thumbnailURL = url(forRelativePath: thumbnailRelativePath)

        try originalData.write(to: originalURL, options: .atomic)
        do {
            try thumbnailData.write(to: thumbnailURL, options: .atomic)
        } catch {
            try? fileManager.removeItem(at: originalURL)
            throw error
        }

        return StoredImagePaths(
            originalRelativePath: originalRelativePath,
            thumbnailRelativePath: thumbnailRelativePath
        )
    }

    func url(forRelativePath relativePath: String) -> URL {
        rootURL.appendingPathComponent(relativePath, isDirectory: false)
    }

    func deleteMemoryFiles(originalRelativePath: String, thumbnailRelativePath: String) throws {
        try validateRelativePath(originalRelativePath, expectedDirectory: "Originals")
        try validateRelativePath(thumbnailRelativePath, expectedDirectory: "Thumbnails")

        for path in [originalRelativePath, thumbnailRelativePath] {
            let url = url(forRelativePath: path)
            if fileManager.fileExists(atPath: url.path) {
                try fileManager.removeItem(at: url)
            }
        }
    }

    private func validateRelativePath(_ path: String, expectedDirectory: String) throws {
        let components = path.split(separator: "/", omittingEmptySubsequences: false).map(String.init)
        let fileName = components.last ?? ""
        var isDirectory: ObjCBool = false
        let exists = fileManager.fileExists(atPath: url(forRelativePath: path).path, isDirectory: &isDirectory)
        guard
            path.isEmpty == false,
            path.contains("..") == false,
            path.hasPrefix("/") == false,
            components.count == 2,
            components.first == expectedDirectory,
            fileName.isEmpty == false,
            URL(fileURLWithPath: fileName).pathExtension.isEmpty == false,
            (exists == false || isDirectory.boolValue == false)
        else {
            throw MemoryFileStoreError.invalidRelativePath(path)
        }
    }

    private func validateMemoryID(_ memoryID: String) throws {
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        guard
            memoryID.isEmpty == false,
            memoryID.rangeOfCharacter(from: allowedCharacters.inverted) == nil
        else {
            throw MemoryFileStoreError.invalidMemoryID(memoryID)
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
