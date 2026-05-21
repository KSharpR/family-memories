import Foundation

struct TimelineSection: Identifiable, Equatable {
    let id: String
    let year: Int
    let month: Int
    let memories: [FamilyMemory]
}

enum TimelineGrouping {
    static func sections(
        for memories: [FamilyMemory],
        calendar: Calendar = .current
    ) -> [TimelineSection] {
        let grouped = Dictionary(grouping: memories) { memory in
            let components = calendar.dateComponents([.year, .month], from: memory.date)
            return YearMonth(year: components.year ?? 1, month: components.month ?? 1)
        }

        return grouped
            .map { key, values in
                TimelineSection(
                    id: String(format: "%04d-%02d", key.year, key.month),
                    year: key.year,
                    month: key.month,
                    memories: values.sorted(by: sortMemories)
                )
            }
            .sorted {
                if $0.year != $1.year { return $0.year > $1.year }
                return $0.month > $1.month
            }
    }

    private static func sortMemories(_ lhs: FamilyMemory, _ rhs: FamilyMemory) -> Bool {
        if lhs.date != rhs.date { return lhs.date > rhs.date }
        if lhs.createdAt != rhs.createdAt { return lhs.createdAt > rhs.createdAt }
        return lhs.id < rhs.id
    }
}

private struct YearMonth: Hashable {
    let year: Int
    let month: Int
}
