import PhotosUI
import SwiftUI

struct TimelineView: View {
    @StateObject private var viewModel: TimelineViewModel
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var importErrorMessage: String?

    let fileStore: MemoryFileStore
    let importService: PhotoImportService
    let reloadToken: UUID
    let onImportedDrafts: ([MemoryDraft]) -> Void
    let onOpenMemory: (FamilyMemory) -> Void

    init(
        repository: MemoryRepositoryProtocol,
        fileStore: MemoryFileStore,
        importService: PhotoImportService,
        reloadToken: UUID,
        onImportedDrafts: @escaping ([MemoryDraft]) -> Void,
        onOpenMemory: @escaping (FamilyMemory) -> Void
    ) {
        _viewModel = StateObject(wrappedValue: TimelineViewModel(repository: repository))
        self.fileStore = fileStore
        self.importService = importService
        self.reloadToken = reloadToken
        self.onImportedDrafts = onImportedDrafts
        self.onOpenMemory = onOpenMemory
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else if viewModel.isEmpty {
                ContentUnavailableView {
                    Label("timeline.empty.title", systemImage: "photo.on.rectangle")
                } description: {
                    Text("timeline.empty.body")
                } actions: {
                    PhotosPicker(
                        selection: $selectedItems,
                        maxSelectionCount: 50,
                        matching: .images
                    ) {
                        Text("timeline.import")
                    }
                        .buttonStyle(.borderedProminent)
                }
            } else if let errorMessage = viewModel.errorMessage {
                ContentUnavailableView {
                    Label("timeline.error.title", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(errorMessage)
                } actions: {
                    Button("common.retry") {
                        Task {
                            await viewModel.load()
                        }
                    }
                    .buttonStyle(.bordered)
                }
            } else {
                List {
                    ForEach(viewModel.sections) { section in
                        Section("\(section.year).\(String(format: "%02d", section.month))") {
                            ForEach(section.memories) { memory in
                                Button {
                                    onOpenMemory(memory)
                                } label: {
                                    HStack(spacing: 12) {
                                        MemoryThumbnailView(imageURL: fileStore.url(forRelativePath: memory.thumbnailPath))

                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(memory.date, style: .date)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)

                                            if memory.story.isEmpty {
                                                Text("memory.story.empty")
                                                    .font(.body)
                                                    .foregroundStyle(.primary)
                                                    .lineLimit(2)
                                            } else {
                                                Text(verbatim: memory.story)
                                                    .font(.body)
                                                    .foregroundStyle(.primary)
                                                    .lineLimit(2)
                                            }

                                            if memory.people.isEmpty == false {
                                                Text(memory.people.joined(separator: " · "))
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                                    .lineLimit(1)
                                            }
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("tab.timeline")
        .toolbar {
            PhotosPicker(
                selection: $selectedItems,
                maxSelectionCount: 50,
                matching: .images
            ) {
                Label("timeline.import", systemImage: "plus")
            }
        }
        .task(id: reloadToken) {
            await viewModel.load()
        }
        .onChange(of: selectedItems) { _, newItems in
            importSelectedItems(newItems)
        }
        .alert("common.error", isPresented: Binding(
            get: { importErrorMessage != nil },
            set: { if $0 == false { importErrorMessage = nil } }
        )) {
            Button("common.ok", role: .cancel) {}
        } message: {
            Text(importErrorMessage ?? "")
        }
    }

    private func importSelectedItems(_ items: [PhotosPickerItem]) {
        guard items.isEmpty == false else { return }

        Task {
            let pickedPhotos = await PhotosPickerAdapter.loadPickedPhotoData(from: items)
            selectedItems = []

            do {
                let result = try importService.importPhotos(pickedPhotos)
                if result.drafts.isEmpty, result.failures.isEmpty == false {
                    importErrorMessage = result.failures.map(\.reason).joined(separator: "\n")
                }
                onImportedDrafts(result.drafts)
            } catch {
                importErrorMessage = error.localizedDescription
            }
        }
    }
}
