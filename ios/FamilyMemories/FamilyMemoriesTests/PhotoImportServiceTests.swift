import XCTest
import UIKit
@testable import FamilyMemories

final class PhotoImportServiceTests: XCTestCase {
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

    func testImportsValidImageIntoDraft() throws {
        let service = PhotoImportService(fileStore: store)
        let result = try service.importPhoto(
            PickedPhotoData(
                filename: "memory.jpg",
                imageData: Self.onePixelJPEG(),
                sourceCreatedAt: Date(timeIntervalSince1970: 100),
                sourceAssetIdentifier: "asset-1"
            )
        )

        XCTAssertEqual(result.failures, [])
        let draft = try XCTUnwrap(result.drafts.first)
        XCTAssertEqual(draft.originalFilename, "memory.jpg")
        XCTAssertEqual(draft.date, Date(timeIntervalSince1970: 100))
        XCTAssertEqual(draft.sourceAssetIdentifier, "asset-1")
        XCTAssertTrue(FileManager.default.fileExists(atPath: store.url(forRelativePath: draft.originalPath).path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: store.url(forRelativePath: draft.thumbnailPath).path))
        XCTAssertNotNil(UIImage(data: try Data(contentsOf: store.url(forRelativePath: draft.thumbnailPath))))
    }

    func testReportsInvalidImageFailureWithoutThrowingBatchAway() throws {
        let service = PhotoImportService(fileStore: store)
        let result = try service.importPhotos([
            PickedPhotoData(filename: "bad.txt", imageData: Data([0]), sourceCreatedAt: nil, sourceAssetIdentifier: nil),
            PickedPhotoData(filename: "good.jpg", imageData: Self.onePixelJPEG(), sourceCreatedAt: nil, sourceAssetIdentifier: nil)
        ])

        XCTAssertEqual(result.drafts.count, 1)
        XCTAssertEqual(result.failures.count, 1)
        XCTAssertEqual(result.failures.first?.filename, "bad.txt")
    }

    func testImportResultHasReviewContentWhenOnlyFailuresArePresent() throws {
        let service = PhotoImportService(fileStore: store)
        let result = try service.importPhotos([
            PickedPhotoData(filename: "bad.txt", imageData: Data([0]), sourceCreatedAt: nil, sourceAssetIdentifier: nil)
        ])

        XCTAssertTrue(result.hasReviewContent)
        XCTAssertEqual(result.failures.first?.displayDescription, "bad.txt: Invalid image data")
    }

    func testReportsThumbnailFailureWithoutThrowingBatchAway() throws {
        var thumbnailCalls = 0
        let service = PhotoImportService(
            fileStore: store,
            idGenerator: { thumbnailCalls == 0 ? "first" : "second" },
            thumbnailGenerator: { _ in
                thumbnailCalls += 1
                if thumbnailCalls == 2 {
                    throw CocoaError(.fileReadCorruptFile)
                }
                return Self.onePixelJPEG()
            }
        )

        let result = try service.importPhotos([
            PickedPhotoData(filename: "first.jpg", imageData: Self.onePixelJPEG(), sourceCreatedAt: nil, sourceAssetIdentifier: nil),
            PickedPhotoData(filename: "bad-thumbnail.jpg", imageData: Self.onePixelJPEG(), sourceCreatedAt: nil, sourceAssetIdentifier: nil)
        ])

        XCTAssertEqual(result.drafts.map(\.originalFilename), ["first.jpg"])
        XCTAssertEqual(result.failures.count, 1)
        XCTAssertEqual(result.failures.first?.filename, "bad-thumbnail.jpg")
        XCTAssertTrue(FileManager.default.fileExists(atPath: store.url(forRelativePath: "Originals/first.jpg").path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: store.url(forRelativePath: "Originals/second.jpg").path))
    }

    func testReportsFileStoreFailureWithoutThrowingBatchAway() throws {
        var ids = ["first", "../escape"]
        let service = PhotoImportService(
            fileStore: store,
            idGenerator: { ids.removeFirst() }
        )

        let result = try service.importPhotos([
            PickedPhotoData(filename: "first.jpg", imageData: Self.onePixelJPEG(), sourceCreatedAt: nil, sourceAssetIdentifier: nil),
            PickedPhotoData(filename: "unsafe-id.jpg", imageData: Self.onePixelJPEG(), sourceCreatedAt: nil, sourceAssetIdentifier: nil)
        ])

        XCTAssertEqual(result.drafts.map(\.originalFilename), ["first.jpg"])
        XCTAssertEqual(result.failures.count, 1)
        XCTAssertEqual(result.failures.first?.filename, "unsafe-id.jpg")
        XCTAssertTrue(FileManager.default.fileExists(atPath: store.url(forRelativePath: "Originals/first.jpg").path))
    }

    private static func onePixelJPEG() -> Data {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1), format: format)
        return renderer.jpegData(withCompressionQuality: 1) { context in
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        }
    }
}
