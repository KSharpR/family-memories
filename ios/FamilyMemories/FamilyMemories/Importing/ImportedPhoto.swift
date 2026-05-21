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
}

struct PhotoImportResult: Equatable {
    var drafts: [MemoryDraft]
    var failures: [ImportFailure]
}
