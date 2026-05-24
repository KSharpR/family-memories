import SwiftUI

struct ImportReviewView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var drafts: [MemoryDraft]
    let failures: [ImportFailure]
    @State private var errorMessage: String?

    let repository: MemoryRepositoryProtocol
    let onSave: () -> Void

    init(
        drafts: [MemoryDraft],
        failures: [ImportFailure] = [],
        repository: MemoryRepositoryProtocol,
        onSave: @escaping () -> Void = {}
    ) {
        _drafts = State(initialValue: drafts)
        self.failures = failures
        self.repository = repository
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            List {
                if failures.isEmpty == false {
                    Section {
                        ForEach(Array(failures.enumerated()), id: \.offset) { _, failure in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(verbatim: failure.filename)
                                    .font(.subheadline.weight(.semibold))
                                Text(verbatim: failure.reason)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                            .accessibilityLabel(Text(verbatim: failure.displayDescription))
                        }
                    } header: {
                        Label("import.review.failed.section", systemImage: "exclamationmark.triangle")
                    } footer: {
                        if drafts.isEmpty == false {
                            Text("import.review.partial.footer")
                        }
                    }
                }

                if drafts.isEmpty == false {
                    Section("import.review.ready.section") {
                        ForEach($drafts) { $draft in
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
                    }
                }
            }
            .overlay {
                if drafts.isEmpty && failures.isEmpty {
                    ContentUnavailableView("import.review.empty", systemImage: "photo.badge.plus")
                }
            }
            .navigationTitle("import.review.title")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(drafts.isEmpty ? "common.done" : "common.cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    if drafts.isEmpty == false {
                        Button("common.save") {
                            saveDrafts()
                        }
                    }
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
