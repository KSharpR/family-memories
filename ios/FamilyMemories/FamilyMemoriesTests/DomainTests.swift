import XCTest
@testable import FamilyMemories

final class DomainTests: XCTestCase {
    func testPeopleTagsAreTrimmedAndDeduplicated() {
        let normalized = PeopleTagNormalizer.normalize([
            " Mom ",
            "",
            "Dad",
            "Mom",
            "  ",
            "外婆"
        ])

        XCTAssertEqual(normalized, ["Mom", "Dad", "外婆"])
    }

    func testMemoryDraftUsesSourceDateUntilUserOverridesDate() {
        let sourceDate = Date(timeIntervalSince1970: 1_700_000_000)
        let manualDate = Date(timeIntervalSince1970: 1_710_000_000)

        var draft = MemoryDraft(
            originalFilename: "family.jpg",
            originalPath: "Originals/family.jpg",
            thumbnailPath: "Thumbnails/family.jpg",
            sourceCreatedAt: sourceDate
        )

        XCTAssertEqual(draft.date, sourceDate)

        draft.date = manualDate
        XCTAssertEqual(draft.date, manualDate)
        XCTAssertEqual(draft.sourceCreatedAt, sourceDate)
    }

    func testTimelineGroupingOrdersYearsAndMonthsDescending() {
        let calendar = Calendar(identifier: .gregorian)
        let memories = [
            FamilyMemory.fixture(id: "old", date: calendar.date(from: DateComponents(year: 2022, month: 7, day: 2))!),
            FamilyMemory.fixture(id: "newer", date: calendar.date(from: DateComponents(year: 2024, month: 3, day: 4))!),
            FamilyMemory.fixture(id: "sameMonth", date: calendar.date(from: DateComponents(year: 2024, month: 3, day: 1))!)
        ]

        let sections = TimelineGrouping.sections(for: memories, calendar: calendar)

        XCTAssertEqual(sections.map(\.id), ["2024-03", "2022-07"])
        XCTAssertEqual(sections[0].memories.map(\.id), ["newer", "sameMonth"])
    }

    func testTimelineGroupingUsesStableOrderingForEqualDates() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let memories = [
            FamilyMemory.fixture(id: "b", date: date, createdAt: Date(timeIntervalSince1970: 100)),
            FamilyMemory.fixture(id: "c", date: date, createdAt: Date(timeIntervalSince1970: 200)),
            FamilyMemory.fixture(id: "a", date: date, createdAt: Date(timeIntervalSince1970: 200))
        ]

        let sections = TimelineGrouping.sections(for: memories)

        XCTAssertEqual(sections[0].memories.map(\.id), ["a", "c", "b"])
    }
}

private extension FamilyMemory {
    static func fixture(id: String, date: Date, createdAt: Date? = nil) -> FamilyMemory {
        FamilyMemory(
            id: id,
            originalFilename: "\(id).jpg",
            originalPath: "Originals/\(id).jpg",
            thumbnailPath: "Thumbnails/\(id).jpg",
            story: "",
            date: date,
            people: [],
            filter: "original",
            createdAt: createdAt ?? date,
            updatedAt: date,
            sourceCreatedAt: date,
            sourceAssetIdentifier: nil
        )
    }
}
