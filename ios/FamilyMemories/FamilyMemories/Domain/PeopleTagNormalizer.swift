import Foundation

enum PeopleTagNormalizer {
    static func normalize(_ rawTags: [String]) -> [String] {
        var seen = Set<String>()
        var normalized: [String] = []

        for tag in rawTags {
            let trimmed = tag.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed.isEmpty == false else { continue }
            guard seen.contains(trimmed) == false else { continue }
            seen.insert(trimmed)
            normalized.append(trimmed)
        }

        return normalized
    }

    static func merge(existing: [String], adding newTags: [String]) -> [String] {
        normalize(existing + newTags)
    }

    static func normalizeText(_ text: String) -> [String] {
        normalize(text.components(separatedBy: CharacterSet(charactersIn: ",，")))
    }
}
