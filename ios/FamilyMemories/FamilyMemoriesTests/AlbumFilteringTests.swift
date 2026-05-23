import XCTest
@testable import FamilyMemories

final class AlbumFilteringTests: XCTestCase {
    func testAvailableYearsAreDescending() {
        let memories = [
            FamilyMemory.fixture(id: "old", date: Date(timeIntervalSince1970: 1_640_995_200)),
            FamilyMemory.fixture(id: "new", date: Date(timeIntervalSince1970: 1_704_067_200)),
            FamilyMemory.fixture(id: "same", date: Date(timeIntervalSince1970: 1_704_153_600))
        ]

        let years = AlbumFiltering.years(in: memories, calendar: Calendar(identifier: .gregorian))

        XCTAssertEqual(years, [2024, 2022])
    }

    func testAvailablePeopleAreNormalizedAndSorted() {
        let memories = [
            FamilyMemory.fixture(id: "one", people: [" Mom ", "Dad"]),
            FamilyMemory.fixture(id: "two", people: ["Mom", "Aunt"])
        ]

        XCTAssertEqual(AlbumFiltering.people(in: memories), ["Aunt", "Dad", "Mom"])
    }

    func testFiltersByYearAndPersonTogether() {
        let calendar = Calendar(identifier: .gregorian)
        let memories = [
            FamilyMemory.fixture(
                id: "match",
                date: calendar.date(from: DateComponents(year: 2024, month: 1, day: 1))!,
                people: ["Mom"]
            ),
            FamilyMemory.fixture(
                id: "wrong-year",
                date: calendar.date(from: DateComponents(year: 2023, month: 1, day: 1))!,
                people: ["Mom"]
            ),
            FamilyMemory.fixture(
                id: "wrong-person",
                date: calendar.date(from: DateComponents(year: 2024, month: 1, day: 1))!,
                people: ["Dad"]
            )
        ]

        let filtered = AlbumFiltering.filtered(
            memories,
            by: AlbumFilterState(year: 2024, person: "Mom"),
            calendar: calendar
        )

        XCTAssertEqual(filtered.map(\.id), ["match"])
    }

    func testPersonFilteringNormalizesStoredPeopleTags() {
        let memories = [
            FamilyMemory.fixture(id: "match", people: [" Mom "]),
            FamilyMemory.fixture(id: "other", people: ["Dad"])
        ]

        let filtered = AlbumFiltering.filtered(
            memories,
            by: AlbumFilterState(person: "Mom")
        )

        XCTAssertEqual(filtered.map(\.id), ["match"])
    }
}

private extension FamilyMemory {
    static func fixture(
        id: String,
        date: Date = Date(timeIntervalSince1970: 1_704_067_200),
        people: [String] = []
    ) -> FamilyMemory {
        FamilyMemory(
            id: id,
            originalFilename: "\(id).jpg",
            originalPath: "Originals/\(id).jpg",
            thumbnailPath: "Thumbnails/\(id).jpg",
            story: "",
            date: date,
            people: people,
            filter: "original",
            createdAt: date,
            updatedAt: date,
            sourceCreatedAt: date,
            sourceAssetIdentifier: nil
        )
    }
}
