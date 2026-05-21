import Foundation

struct MemoryDraft: Equatable, Identifiable {
    let id: String
    var originalFilename: String
    var originalPath: String
    var thumbnailPath: String
    var story: String
    var date: Date
    var people: [String]
    var filter: String
    var sourceCreatedAt: Date?
    var sourceAssetIdentifier: String?

    init(
        id: String = UUID().uuidString,
        originalFilename: String,
        originalPath: String,
        thumbnailPath: String,
        story: String = "",
        date: Date? = nil,
        people: [String] = [],
        filter: String = "original",
        sourceCreatedAt: Date? = nil,
        sourceAssetIdentifier: String? = nil
    ) {
        self.id = id
        self.originalFilename = originalFilename
        self.originalPath = originalPath
        self.thumbnailPath = thumbnailPath
        self.story = story
        self.date = date ?? sourceCreatedAt ?? Date()
        self.people = PeopleTagNormalizer.normalize(people)
        self.filter = filter
        self.sourceCreatedAt = sourceCreatedAt
        self.sourceAssetIdentifier = sourceAssetIdentifier
    }

    func persisted(now: Date = Date()) -> FamilyMemory {
        FamilyMemory(
            id: id,
            originalFilename: originalFilename,
            originalPath: originalPath,
            thumbnailPath: thumbnailPath,
            story: story,
            date: date,
            people: PeopleTagNormalizer.normalize(people),
            filter: filter,
            createdAt: now,
            updatedAt: now,
            sourceCreatedAt: sourceCreatedAt,
            sourceAssetIdentifier: sourceAssetIdentifier
        )
    }
}
