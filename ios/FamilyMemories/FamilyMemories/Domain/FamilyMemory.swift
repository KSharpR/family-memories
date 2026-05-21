import Foundation

struct FamilyMemory: Identifiable, Equatable, Hashable {
    let id: String
    var originalFilename: String
    var originalPath: String
    var thumbnailPath: String
    var story: String
    var date: Date
    var people: [String]
    var filter: String
    var createdAt: Date
    var updatedAt: Date
    var sourceCreatedAt: Date?
    var sourceAssetIdentifier: String?
}
