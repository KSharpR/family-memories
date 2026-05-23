import Foundation

struct AlbumFilterState: Equatable {
    var year: Int?
    var person: String?

    var isActive: Bool {
        year != nil || person != nil
    }
}

enum AlbumFiltering {
    static func years(
        in memories: [FamilyMemory],
        calendar: Calendar = .current
    ) -> [Int] {
        Array(Set(memories.map { memory in
            calendar.component(.year, from: memory.date)
        }))
        .sorted(by: >)
    }

    static func people(in memories: [FamilyMemory]) -> [String] {
        let normalizedPeople = memories.flatMap { PeopleTagNormalizer.normalize($0.people) }
        return Array(Set(normalizedPeople)).sorted {
            $0.localizedStandardCompare($1) == .orderedAscending
        }
    }

    static func filtered(
        _ memories: [FamilyMemory],
        by filter: AlbumFilterState,
        calendar: Calendar = .current
    ) -> [FamilyMemory] {
        memories.filter { memory in
            if let year = filter.year, calendar.component(.year, from: memory.date) != year {
                return false
            }

            if let person = filter.person,
               PeopleTagNormalizer.normalize(memory.people).contains(person) == false {
                return false
            }

            return true
        }
    }
}
