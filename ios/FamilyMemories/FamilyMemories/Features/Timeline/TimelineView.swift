import PhotosUI
import SwiftUI

struct TimelineView: View {
    @StateObject private var viewModel: TimelineViewModel
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var filter = AlbumFilterState()
    @State private var importErrorMessage: String?

    let fileStore: MemoryFileStore
    let importService: PhotoImportService
    let reloadToken: UUID
    let onImportResult: (PhotoImportResult) -> Void
    let onOpenMemory: (FamilyMemory) -> Void
    private let calendar = Calendar.current

    init(
        repository: MemoryRepositoryProtocol,
        fileStore: MemoryFileStore,
        importService: PhotoImportService,
        reloadToken: UUID,
        onImportResult: @escaping (PhotoImportResult) -> Void,
        onOpenMemory: @escaping (FamilyMemory) -> Void
    ) {
        _viewModel = StateObject(wrappedValue: TimelineViewModel(repository: repository))
        self.fileStore = fileStore
        self.importService = importService
        self.reloadToken = reloadToken
        self.onImportResult = onImportResult
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
                    Section {
                        MemoryFilterBar(
                            filter: $filter,
                            years: availableYears,
                            people: availablePeople,
                            onReset: clearFilters
                        )
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))

                    if filteredMemories.isEmpty {
                        Section {
                            ContentUnavailableView {
                                Label("album.filter.empty.title", systemImage: "line.3.horizontal.decrease.circle")
                            } description: {
                                Text("album.filter.empty.body")
                            } actions: {
                                Button("common.reset") {
                                    clearFilters()
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }

                    ForEach(filteredSections) { section in
                        Section("\(section.year).\(String(format: "%02d", section.month))") {
                            ForEach(section.memories) { memory in
                                Button {
                                    onOpenMemory(memory)
                                } label: {
                                    TimelineMemoryRow(
                                        memory: memory,
                                        imageURL: fileStore.url(forRelativePath: memory.thumbnailPath)
                                    )
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
                if result.hasReviewContent {
                    onImportResult(result)
                }
            } catch {
                importErrorMessage = error.localizedDescription
            }
        }
    }

    private var allMemories: [FamilyMemory] {
        viewModel.sections.flatMap(\.memories)
    }

    private var availableYears: [Int] {
        AlbumFiltering.years(in: allMemories, calendar: calendar)
    }

    private var availablePeople: [String] {
        AlbumFiltering.people(in: allMemories)
    }

    private var filteredMemories: [FamilyMemory] {
        AlbumFiltering.filtered(allMemories, by: filter, calendar: calendar)
    }

    private var filteredSections: [TimelineSection] {
        TimelineGrouping.sections(for: filteredMemories, calendar: calendar)
    }

    private func clearFilters() {
        filter = AlbumFilterState()
    }
}

private struct TimelineMemoryRow: View {
    let memory: FamilyMemory
    let imageURL: URL

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            MemoryThumbnailView(imageURL: imageURL, size: CGSize(width: 78, height: 78), cornerRadius: 8)

            VStack(alignment: .leading, spacing: 7) {
                Text(memory.date, style: .date)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                if memory.story.isEmpty {
                    Text("memory.story.empty")
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                } else {
                    Text(verbatim: memory.story)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                }

                if memory.people.isEmpty == false {
                    Label {
                        Text(verbatim: memory.people.joined(separator: " · "))
                            .lineLimit(1)
                    } icon: {
                        Image(systemName: "person.2")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 6)
    }
}
