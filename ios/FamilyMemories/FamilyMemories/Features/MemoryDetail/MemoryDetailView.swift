import SwiftUI

struct MemoryDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var memory: FamilyMemory
    @State private var errorMessage: String?
    @State private var isDeleteConfirmationPresented = false

    let repository: MemoryRepositoryProtocol
    let fileStore: MemoryFileStore
    let onChange: () -> Void

    init(
        memory: FamilyMemory,
        repository: MemoryRepositoryProtocol,
        fileStore: MemoryFileStore,
        onChange: @escaping () -> Void = {}
    ) {
        _memory = State(initialValue: memory)
        self.repository = repository
        self.fileStore = fileStore
        self.onChange = onChange
    }

    var body: some View {
        Form {
            Section {
                MemoryThumbnailView(
                    imageURL: fileStore.url(forRelativePath: memory.originalPath),
                    size: nil,
                    cornerRadius: 10
                )
                .frame(maxWidth: .infinity)
                .frame(height: 280)
            }

            Section("memory.metadata") {
                DatePicker("memory.date", selection: $memory.date, displayedComponents: .date)

                TextField(
                    "memory.people",
                    text: Binding(
                        get: { memory.people.joined(separator: ", ") },
                        set: { memory.people = PeopleTagNormalizer.normalize($0.split(separator: ",").map(String.init)) }
                    )
                )

                TextField("memory.story", text: $memory.story, axis: .vertical)
                    .lineLimit(4...12)
            }

            Section {
                Button(role: .destructive) {
                    isDeleteConfirmationPresented = true
                } label: {
                    Label("memory.delete", systemImage: "trash")
                }
            }
        }
        .navigationTitle("memory.detail.title")
        .toolbar {
            Button("common.save") {
                saveMemory()
            }
        }
        .confirmationDialog(
            "memory.delete.confirmation.title",
            isPresented: $isDeleteConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button("memory.delete", role: .destructive) {
                deleteMemory()
            }
            Button("common.cancel", role: .cancel) {}
        } message: {
            Text("memory.delete.confirmation.message")
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

    private func saveMemory() {
        do {
            memory.updatedAt = Date()
            try repository.save(memory)
            onChange()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func deleteMemory() {
        do {
            try repository.delete(id: memory.id)
            try? fileStore.deleteMemoryFiles(
                originalRelativePath: memory.originalPath,
                thumbnailRelativePath: memory.thumbnailPath
            )
            onChange()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
