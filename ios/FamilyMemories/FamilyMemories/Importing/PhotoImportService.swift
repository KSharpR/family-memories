import Foundation
import ImageIO
import UIKit

final class PhotoImportService {
    private let fileStore: MemoryFileStore

    init(fileStore: MemoryFileStore) {
        self.fileStore = fileStore
    }

    func importPhoto(_ pickedPhoto: PickedPhotoData) throws -> PhotoImportResult {
        try importPhotos([pickedPhoto])
    }

    func importPhotos(_ pickedPhotos: [PickedPhotoData]) throws -> PhotoImportResult {
        var drafts: [MemoryDraft] = []
        var failures: [ImportFailure] = []

        for pickedPhoto in pickedPhotos {
            guard UIImage(data: pickedPhoto.imageData) != nil else {
                failures.append(ImportFailure(filename: pickedPhoto.filename, reason: "Invalid image data"))
                continue
            }

            let memoryID = UUID().uuidString
            let thumbnailData = try makeThumbnailJPEGData(from: pickedPhoto.imageData)
            let paths = try fileStore.writeImageFiles(
                memoryID: memoryID,
                originalFilename: pickedPhoto.filename,
                originalData: pickedPhoto.imageData,
                thumbnailData: thumbnailData
            )

            drafts.append(
                MemoryDraft(
                    id: memoryID,
                    originalFilename: pickedPhoto.filename,
                    originalPath: paths.originalRelativePath,
                    thumbnailPath: paths.thumbnailRelativePath,
                    sourceCreatedAt: pickedPhoto.sourceCreatedAt,
                    sourceAssetIdentifier: pickedPhoto.sourceAssetIdentifier
                )
            )
        }

        return PhotoImportResult(drafts: drafts, failures: failures)
    }

    private func makeThumbnailJPEGData(from data: Data) throws -> Data {
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: 420,
            kCGImageSourceCreateThumbnailWithTransform: true
        ]

        guard
            let source = CGImageSourceCreateWithData(data as CFData, nil),
            let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }

        let image = UIImage(cgImage: thumbnail)
        guard let jpegData = image.jpegData(compressionQuality: 0.82) else {
            throw CocoaError(.fileWriteUnknown)
        }

        return jpegData
    }
}
