import SwiftUI

struct ImportReviewView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var drafts: [MemoryDraft]
    @State private var errorMessage: String?

    let repository: MemoryRepositoryProtocol
    let onSave: () -> Void

    init(
        drafts: [MemoryDraft],
        repository: MemoryRepositoryProtocol,
        onSave: @escaping () -> Void = {}
    ) {
        _drafts = State(initialValue: drafts)
        self.repository = repository
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            List($drafts) { $draft in
                VStack(alignment: .leading, spacing: 10) {
                    DatePicker("memory.date", selection: $draft.date, displayedComponents: .date)

                    TextField(
                        "memory.people",
                        text: Binding(
                            get: { draft.people.joined(separator: ", ") },
                            set: { draft.people = PeopleTagNormalizer.normalize($0.split(separator: ",").map(String.init)) }
                        )
                    )

                    TextField("memory.story", text: $draft.story, axis: .vertical)
                        .lineLimit(3...8)
                }
                .padding(.vertical, 8)
            }
            .overlay {
                if drafts.isEmpty {
                    ContentUnavailableView("import.review.empty", systemImage: "photo.badge.plus")
                }
            }
            .navigationTitle("import.review.title")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("common.done") {
                        saveDrafts()
                    }
                    .disabled(drafts.isEmpty)
                }
            }
            .alert("common.error", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if $0 == false { errorMessage = nil } }
            )) {
                Button("common.ok", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private func saveDrafts() {
        do {
            for draft in drafts {
                try repository.save(draft.persisted())
            }
            onSave()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
