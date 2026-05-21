import XCTest
@testable import FamilyMemories

final class MemoryFileStoreTests: XCTestCase {
    private var rootURL: URL!
    private var store: MemoryFileStore!

    override func setUpWithError() throws {
        rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        store = try MemoryFileStore(rootURL: rootURL)
    }

    override func tearDownWithError() throws {
        if let rootURL {
            try? FileManager.default.removeItem(at: rootURL)
        }
    }

    func testCreatesExpectedDirectories() throws {
        XCTAssertTrue(FileManager.default.fileExists(atPath: store.originalsDirectory.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: store.thumbnailsDirectory.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: store.backupsDirectory.path))
    }

    func testWritesOriginalAndThumbnailUsingStableMemoryId() throws {
        let original = Data([1, 2, 3])
        let thumbnail = Data([4, 5, 6])

        let paths = try store.writeImageFiles(
            memoryID: "abc",
            originalFilename: "photo.JPG",
            originalData: original,
            thumbnailData: thumbnail
        )

        XCTAssertEqual(paths.originalRelativePath, "Originals/abc.jpg")
        XCTAssertEqual(paths.thumbnailRelativePath, "Thumbnails/abc.jpg")
        XCTAssertEqual(try Data(contentsOf: store.url(forRelativePath: paths.originalRelativePath)), original)
        XCTAssertEqual(try Data(contentsOf: store.url(forRelativePath: paths.thumbnailRelativePath)), thumbnail)
    }

    func testDeleteMemoryFilesRemovesOriginalAndThumbnail() throws {
        let paths = try store.writeImageFiles(
            memoryID: "gone",
            originalFilename: "gone.png",
            originalData: Data([9]),
            thumbnailData: Data([8])
        )

        try store.deleteMemoryFiles(
            originalRelativePath: paths.originalRelativePath,
            thumbnailRelativePath: paths.thumbnailRelativePath
        )

        XCTAssertFalse(FileManager.default.fileExists(atPath: store.url(forRelativePath: paths.originalRelativePath).path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: store.url(forRelativePath: paths.thumbnailRelativePath).path))
    }

    func testDeleteMemoryFilesRejectsUnsafeRelativePaths() throws {
        XCTAssertThrowsError(
            try store.deleteMemoryFiles(
                originalRelativePath: "../outside.jpg",
                thumbnailRelativePath: "Thumbnails/safe.jpg"
            )
        ) { error in
            XCTAssertEqual(error as? MemoryFileStoreError, .invalidRelativePath("../outside.jpg"))
        }
    }

    func testDeleteMemoryFilesRejectsDirectoryRelativePaths() throws {
        XCTAssertThrowsError(
            try store.deleteMemoryFiles(
                originalRelativePath: "Originals",
                thumbnailRelativePath: "Thumbnails/safe.jpg"
            )
        ) { error in
            XCTAssertEqual(error as? MemoryFileStoreError, .invalidRelativePath("Originals"))
        }

        var isDirectory: ObjCBool = false
        XCTAssertTrue(FileManager.default.fileExists(atPath: store.originalsDirectory.path, isDirectory: &isDirectory))
        XCTAssertTrue(isDirectory.boolValue)
    }

    func testDeleteMemoryFilesValidatesAllPathsBeforeRemovingFiles() throws {
        let paths = try store.writeImageFiles(
            memoryID: "kept",
            originalFilename: "kept.jpg",
            originalData: Data([1]),
            thumbnailData: Data([2])
        )

        XCTAssertThrowsError(
            try store.deleteMemoryFiles(
                originalRelativePath: paths.originalRelativePath,
                thumbnailRelativePath: "../unsafe.jpg"
            )
        ) { error in
            XCTAssertEqual(error as? MemoryFileStoreError, .invalidRelativePath("../unsafe.jpg"))
        }

        XCTAssertTrue(FileManager.default.fileExists(atPath: store.url(forRelativePath: paths.originalRelativePath).path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: store.url(forRelativePath: paths.thumbnailRelativePath).path))
    }

    func testWriteImageFilesRejectsUnsafeMemoryID() throws {
        XCTAssertThrowsError(
            try store.writeImageFiles(
                memoryID: "../escape",
                originalFilename: "photo.jpg",
                originalData: Data([1]),
                thumbnailData: Data([2])
            )
        ) { error in
            XCTAssertEqual(error as? MemoryFileStoreError, .invalidMemoryID("../escape"))
        }
    }

    func testWriteImageFilesRollsBackOriginalWhenThumbnailWriteFails() throws {
        try FileManager.default.removeItem(at: store.thumbnailsDirectory)
        try Data([0]).write(to: store.thumbnailsDirectory)

        XCTAssertThrowsError(
            try store.writeImageFiles(
                memoryID: "partial",
                originalFilename: "photo.jpg",
                originalData: Data([1]),
                thumbnailData: Data([2])
            )
        )

        XCTAssertFalse(FileManager.default.fileExists(atPath: store.url(forRelativePath: "Originals/partial.jpg").path))
    }
}
