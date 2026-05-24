import Foundation

struct WebAlbumImportCandidate: Equatable {
    let id: String
    let originalFilename: String
    let originalData: Data
    let story: String
    let date: Date
    let people: [String]
    let filter: String
    let createdAt: Date
    let updatedAt: Date
}

enum WebAlbumImportError: LocalizedError, Equatable {
    case invalidAlbum
    case invalidMemoryID(String)
    case duplicateMemoryID(String)
    case invalidImageDataURL
    case invalidDate(String)

    var errorDescription: String? {
        switch self {
        case .invalidAlbum:
            return "This web album JSON is not compatible."
        case let .invalidMemoryID(id):
            return "This web album contains an unsupported memory ID: \(id)."
        case let .duplicateMemoryID(id):
            return "This web album contains duplicate memory ID: \(id)."
        case .invalidImageDataURL:
            return "This web album contains an unsupported image data URL."
        case let .invalidDate(date):
            return "This web album contains an unsupported date: \(date)."
        }
    }
}

final class WebAlbumImportAdapter {
    private let decoder = JSONDecoder()
    private let isoDateFormatter: ISO8601DateFormatter

    init() {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        isoDateFormatter = formatter
    }

    func importCandidates(from data: Data) throws -> [WebAlbumImportCandidate] {
        let album = try decodeAlbum(from: data)
        var seenIDs = Set<String>()

        return try album.memories.map { memory in
            let id = memory.id.trimmingCharacters(in: .whitespacesAndNewlines)
            guard id.isEmpty == false else {
                throw WebAlbumImportError.invalidAlbum
            }
            guard isValidMemoryID(id) else {
                throw WebAlbumImportError.invalidMemoryID(id)
            }
            guard seenIDs.insert(id).inserted else {
                throw WebAlbumImportError.duplicateMemoryID(id)
            }

            let image = try parseImageDataURL(memory.photoDataUrl)
            let createdAt = try parseTimestamp(memory.createdAt)
            let updatedAt = try parseTimestamp(memory.updatedAt ?? memory.createdAt)
            let memoryDate = try memory.date.map(parseDateOnly) ?? createdAt

            return WebAlbumImportCandidate(
                id: id,
                originalFilename: "\(id).\(image.fileExtension)",
                originalData: image.data,
                story: memory.story ?? "",
                date: memoryDate,
                people: PeopleTagNormalizer.normalize(memory.people ?? []),
                filter: memory.filter == "sepia" ? "sepia" : "original",
                createdAt: createdAt,
                updatedAt: updatedAt
            )
        }
    }

    private func decodeAlbum(from data: Data) throws -> WebAlbumDTO {
        do {
            return try decoder.decode(WebAlbumDTO.self, from: data)
        } catch {
            throw WebAlbumImportError.invalidAlbum
        }
    }

    private func parseTimestamp(_ value: String) throws -> Date {
        if let date = isoDateFormatter.date(from: value) {
            return date
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: value) {
            return date
        }

        throw WebAlbumImportError.invalidDate(value)
    }

    private func parseDateOnly(_ value: String) throws -> Date {
        let parts = value.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else {
            throw WebAlbumImportError.invalidDate(value)
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        var components = DateComponents()
        components.calendar = calendar
        components.timeZone = calendar.timeZone
        components.year = parts[0]
        components.month = parts[1]
        components.day = parts[2]

        guard
            let date = calendar.date(from: components),
            calendar.component(.year, from: date) == parts[0],
            calendar.component(.month, from: date) == parts[1],
            calendar.component(.day, from: date) == parts[2]
        else {
            throw WebAlbumImportError.invalidDate(value)
        }

        return date
    }

    private func parseImageDataURL(_ value: String) throws -> ParsedWebImage {
        let parts = value.split(separator: ",", maxSplits: 1, omittingEmptySubsequences: false)
        guard parts.count == 2 else {
            throw WebAlbumImportError.invalidImageDataURL
        }

        let metadata = String(parts[0]).lowercased()
        guard metadata.hasPrefix("data:image/"), metadata.hasSuffix(";base64") else {
            throw WebAlbumImportError.invalidImageDataURL
        }

        let mimeSubtype = metadata
            .dropFirst("data:image/".count)
            .dropLast(";base64".count)

        let fileExtension: String
        switch mimeSubtype {
        case "jpeg", "jpg":
            fileExtension = "jpg"
        case "png", "webp", "gif":
            fileExtension = String(mimeSubtype)
        default:
            throw WebAlbumImportError.invalidImageDataURL
        }

        guard let data = Data(base64Encoded: String(parts[1])) else {
            throw WebAlbumImportError.invalidImageDataURL
        }

        return ParsedWebImage(fileExtension: fileExtension, data: data)
    }

    private func isValidMemoryID(_ id: String) -> Bool {
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        return id.rangeOfCharacter(from: allowedCharacters.inverted) == nil
    }
}

private struct ParsedWebImage {
    let fileExtension: String
    let data: Data
}

private struct WebAlbumDTO: Decodable {
    let memories: [WebMemoryDTO]
}

private struct WebMemoryDTO: Decodable {
    let id: String
    let photoDataUrl: String
    let story: String?
    let date: String?
    let people: [String]?
    let filter: String?
    let createdAt: String
    let updatedAt: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case photoDataUrl
        case photo
        case story
        case text
        case date
        case people
        case filter
        case createdAt
        case updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        if let photoDataUrl = try container.decodeIfPresent(String.self, forKey: .photoDataUrl) {
            self.photoDataUrl = photoDataUrl
        } else if let photo = try container.decodeIfPresent(String.self, forKey: .photo) {
            photoDataUrl = photo
        } else {
            throw WebAlbumImportError.invalidImageDataURL
        }
        story = try container.decodeIfPresent(String.self, forKey: .story)
            ?? container.decodeIfPresent(String.self, forKey: .text)
        date = try container.decodeIfPresent(String.self, forKey: .date)
        people = try container.decodeIfPresent([String].self, forKey: .people)
        filter = try container.decodeIfPresent(String.self, forKey: .filter)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
    }
}
