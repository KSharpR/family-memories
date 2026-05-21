import Foundation

struct BackupMemoryDTO: Codable, Equatable {
    let id: String
    let originalFilename: String
    let originalPath: String
    let thumbnailPath: String
    let story: String
    let date: Date
    let people: [String]
    let filter: String
    let createdAt: Date
    let updatedAt: Date
    let sourceCreatedAt: Date?
    let sourceAssetIdentifier: String?

    init(memory: FamilyMemory) {
        id = memory.id
        originalFilename = memory.originalFilename
        originalPath = memory.originalPath
        thumbnailPath = memory.thumbnailPath
        story = memory.story
        date = memory.date
        people = memory.people
        filter = memory.filter
        createdAt = memory.createdAt
        updatedAt = memory.updatedAt
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
            people: PeopleTagNormalizer.normalize(people),
            filter: filter,
            createdAt: createdAt,
            updatedAt: updatedAt,
            sourceCreatedAt: sourceCreatedAt,
            sourceAssetIdentifier: sourceAssetIdentifier
        )
    }
}
