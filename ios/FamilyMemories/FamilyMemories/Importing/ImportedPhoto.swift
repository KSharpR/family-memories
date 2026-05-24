import Foundation

struct PickedPhotoData: Equatable {
    let filename: String
    let imageData: Data
    let sourceCreatedAt: Date?
    let sourceAssetIdentifier: String?
}

struct ImportFailure: Equatable {
    let filename: String
    let reason: String

    var displayDescription: String {
        "\(filename): \(reason)"
    }
}

struct PhotoImportResult: Equatable {
    var drafts: [MemoryDraft]
    var failures: [ImportFailure]

    var hasReviewContent: Bool {
        drafts.isEmpty == false || failures.isEmpty == false
    }
}
