import Combine
import Foundation

@MainActor
final class TimelineViewModel: ObservableObject {
    @Published private(set) var sections: [TimelineSection] = []
    @Published private(set) var errorMessage: String?
    @Published private(set) var isLoading = false

    private let repository: MemoryRepositoryProtocol
    private let calendar: Calendar

    var isEmpty: Bool {
        sections.isEmpty && isLoading == false && errorMessage == nil
    }

    init(repository: MemoryRepositoryProtocol, calendar: Calendar = .current) {
        self.repository = repository
        self.calendar = calendar
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        await Task.yield()

        defer { isLoading = false }

        do {
            let memories = try await repository.fetchAll()
            sections = TimelineGrouping.sections(for: memories, calendar: calendar)
            errorMessage = nil
        } catch {
            sections = []
            errorMessage = error.localizedDescription
        }
    }
}
