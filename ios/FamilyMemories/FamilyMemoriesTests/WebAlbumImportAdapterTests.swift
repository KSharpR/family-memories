import XCTest
@testable import FamilyMemories

final class WebAlbumImportAdapterTests: XCTestCase {
    func testParsesCompatibleWebAlbumMemoryFields() throws {
        let json = """
        {
          "id": "local-album",
          "title": "家族回忆记录册",
          "memories": [
            {
              "id": "web-1",
              "photoDataUrl": "data:image/png;base64,AQID",
              "story": "一起包饺子的下午",
              "date": "2026-05-20",
              "people": [" 奶奶 ", "我", "奶奶"],
              "filter": "none",
              "createdAt": "2026-05-01T12:00:00.000Z",
              "updatedAt": "2026-05-02T13:30:00.000Z"
            }
          ],
          "settings": {
            "theme": "warm-paper",
            "sortOrder": "desc"
          },
          "createdAt": "2026-05-01T12:00:00.000Z",
          "updatedAt": "2026-05-02T13:30:00.000Z"
        }
        """.data(using: .utf8)!

        let candidates = try WebAlbumImportAdapter().importCandidates(from: json)

        XCTAssertEqual(candidates.count, 1)
        let candidate = try XCTUnwrap(candidates.first)
        XCTAssertEqual(candidate.id, "web-1")
        XCTAssertEqual(candidate.originalFilename, "web-1.png")
        XCTAssertEqual(candidate.originalData, Data([1, 2, 3]))
        XCTAssertEqual(candidate.story, "一起包饺子的下午")
        XCTAssertEqual(candidate.date, Date(timeIntervalSince1970: 1_779_235_200))
        XCTAssertEqual(candidate.people, ["奶奶", "我"])
        XCTAssertEqual(candidate.filter, "original")
        XCTAssertEqual(candidate.createdAt, Date(timeIntervalSince1970: 1_777_636_800))
        XCTAssertEqual(candidate.updatedAt, Date(timeIntervalSince1970: 1_777_728_600))
    }

    func testUsesCreatedAtAsMemoryDateWhenWebDateIsMissing() throws {
        let json = """
        {
          "memories": [
            {
              "id": "web-2",
              "photoDataUrl": "data:image/jpeg;base64,BAUG",
              "story": "",
              "date": null,
              "people": [],
              "filter": "sepia",
              "createdAt": "2026-06-01T08:15:00.000Z",
              "updatedAt": "2026-06-01T08:15:00.000Z"
            }
          ]
        }
        """.data(using: .utf8)!

        let candidate = try XCTUnwrap(WebAlbumImportAdapter().importCandidates(from: json).first)

        XCTAssertEqual(candidate.originalFilename, "web-2.jpg")
        XCTAssertEqual(candidate.originalData, Data([4, 5, 6]))
        XCTAssertEqual(candidate.date, Date(timeIntervalSince1970: 1_780_301_700))
        XCTAssertEqual(candidate.filter, "sepia")
    }

    func testAcceptsLegacyWebPhotoAndTextFields() throws {
        let json = """
        {
          "memories": [
            {
              "id": "legacy-1",
              "photo": "data:image/gif;base64,BwgJ",
              "text": "旧版本故事字段",
              "date": "2026-07-03",
              "people": ["爸爸"],
              "createdAt": "2026-07-03T01:00:00.000Z",
              "updatedAt": "2026-07-03T02:00:00.000Z"
            }
          ]
        }
        """.data(using: .utf8)!

        let candidate = try XCTUnwrap(WebAlbumImportAdapter().importCandidates(from: json).first)

        XCTAssertEqual(candidate.originalFilename, "legacy-1.gif")
        XCTAssertEqual(candidate.originalData, Data([7, 8, 9]))
        XCTAssertEqual(candidate.story, "旧版本故事字段")
        XCTAssertEqual(candidate.people, ["爸爸"])
    }

    func testRejectsDuplicateIDsAndMalformedImageDataURLs() {
        let duplicateIDs = """
        {
          "memories": [
            {
              "id": "web-1",
              "photoDataUrl": "data:image/png;base64,AQID",
              "createdAt": "2026-05-01T12:00:00.000Z",
              "updatedAt": "2026-05-02T13:30:00.000Z"
            },
            {
              "id": "web-1",
              "photoDataUrl": "data:image/png;base64,AQID",
              "createdAt": "2026-05-01T12:00:00.000Z",
              "updatedAt": "2026-05-02T13:30:00.000Z"
            }
          ]
        }
        """.data(using: .utf8)!
        let malformedImage = """
        {
          "memories": [
            {
              "id": "web-1",
              "photoDataUrl": "data:image/svg+xml;base64,AQID",
              "createdAt": "2026-05-01T12:00:00.000Z",
              "updatedAt": "2026-05-02T13:30:00.000Z"
            }
          ]
        }
        """.data(using: .utf8)!

        XCTAssertThrowsError(try WebAlbumImportAdapter().importCandidates(from: duplicateIDs)) { error in
            XCTAssertEqual(error as? WebAlbumImportError, .duplicateMemoryID("web-1"))
        }
        XCTAssertThrowsError(try WebAlbumImportAdapter().importCandidates(from: malformedImage)) { error in
            XCTAssertEqual(error as? WebAlbumImportError, .invalidImageDataURL)
        }
    }
}
