import Foundation
import SwiftData

@MainActor
protocol MemoryRepositoryProtocol {
    func fetchAll() async throws -> [FamilyMemory]
    func fetch(id: String) async throws -> FamilyMemory?
    func save(_ memory: FamilyMemory) throws
    func delete(id: String) throws
}

@MainActor
final class MemoryRepository: MemoryRepositoryProtocol {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll() async throws -> [FamilyMemory] {
        let descriptor = FetchDescriptor<MemoryRecord>(
            sortBy: [
                SortDescriptor(\.date, order: .reverse),
                SortDescriptor(\.createdAt, order: .reverse),
                SortDescriptor(\.id)
            ]
        )
        return try context.fetch(descriptor).map(\.domain)
    }

    func fetch(id: String) async throws -> FamilyMemory? {
        let descriptor = FetchDescriptor<MemoryRecord>(
            predicate: #Predicate { $0.id == id }
        )
        return try context.fetch(descriptor).first?.domain
    }

    func save(_ memory: FamilyMemory) throws {
        let memoryID = memory.id
        let descriptor = FetchDescriptor<MemoryRecord>(
            predicate: #Predicate { $0.id == memoryID }
        )

        if let existing = try context.fetch(descriptor).first {
            existing.apply(memory)
        } else {
            context.insert(MemoryRecord(memory: memory))
        }

        try context.save()
    }

    func delete(id: String) throws {
        let descriptor = FetchDescriptor<MemoryRecord>(
            predicate: #Predicate { $0.id == id }
        )

        for record in try context.fetch(descriptor) {
            context.delete(record)
        }

        try context.save()
    }
}
