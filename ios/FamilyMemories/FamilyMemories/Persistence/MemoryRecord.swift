import Foundation
import SwiftData

@Model
final class MemoryRecord {
    @Attribute(.unique) var id: String
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

    init(memory: FamilyMemory) {
        self.id = memory.id
        self.originalFilename = memory.originalFilename
        self.originalPath = memory.originalPath
        self.thumbnailPath = memory.thumbnailPath
        self.story = memory.story
        self.date = memory.date
        self.people = PeopleTagNormalizer.normalize(memory.people)
        self.filter = memory.filter
        self.createdAt = memory.createdAt
        self.updatedAt = memory.updatedAt
        self.sourceCreatedAt = memory.sourceCreatedAt
        self.sourceAssetIdentifier = memory.sourceAssetIdentifier
    }

    func apply(_ memory: FamilyMemory) {
        originalFilename = memory.originalFilename
        originalPath = memory.originalPath
        thumbnailPath = memory.thumbnailPath
        story = memory.story
        date = memory.date
        people = PeopleTagNormalizer.normalize(memory.people)
        filter = memory.filter
        createdAt = memory.createdAt
        updatedAt = Date()
        sourceCreatedAt = memory.sourceCreatedAt
        sourceAssetIdentifier = memory.sourceAssetIdentifier
    }

    var domain: FamilyMemory {
        FamilyMemory(
            id: id,
            originalFilename: originalFilename,
            originalPath: originalPath,
            thumbnailPath: thumbnailPath,
            story: story,
            date: date,
            people: people,
            filter: filter,
            createdAt: createdAt,
            updatedAt: updatedAt,
            sourceCreatedAt: sourceCreatedAt,
            sourceAssetIdentifier: sourceAssetIdentifier
        )
    }
}
