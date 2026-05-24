import SwiftUI

struct AlbumView: View {
    @StateObject private var viewModel: TimelineViewModel
    @State private var filter = AlbumFilterState()
    @State private var previewMemory: FamilyMemory?
    @State private var isSelectionMode = false
    @State private var selectedMemoryIDs: Set<String> = []
    @State private var isDeleteConfirmationPresented = false
    @State private var isBatchTagSheetPresented = false
    @State private var batchPeopleInput = ""
    @State private var errorMessage: String?

    let repository: MemoryRepositoryProtocol
    let fileStore: MemoryFileStore
    let reloadToken: UUID
    let onOpenMemory: (FamilyMemory) -> Void
    let onChange: () -> Void

    private let calendar = Calendar.current
    private let columns = [
        GridItem(.adaptive(minimum: 108, maximum: 180), spacing: 8)
    ]

    init(
        repository: MemoryRepositoryProtocol,
        fileStore: MemoryFileStore,
        reloadToken: UUID,
        onOpenMemory: @escaping (FamilyMemory) -> Void,
        onChange: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: TimelineViewModel(repository: repository))
        self.repository = repository
        self.fileStore = fileStore
        self.reloadToken = reloadToken
        self.onOpenMemory = onOpenMemory
        self.onChange = onChange
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else if viewModel.isEmpty {
                ContentUnavailableView {
                    Label("album.empty.title", systemImage: "book.pages")
                } description: {
                    Text("album.empty.body")
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
                albumContent
            }
        }
        .navigationTitle("tab.album")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if allMemories.isEmpty == false {
                    Button(isSelectionMode ? "common.done" : "album.select") {
                        toggleSelectionMode()
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if isSelectionMode && allMemories.isEmpty == false {
                AlbumSelectionBar(
                    selectedCount: selectedMemoryIDs.count,
                    allVisibleSelected: allVisibleSelected,
                    canSelectVisible: visibleMemoryIDs.isEmpty == false,
                    onToggleSelectAll: toggleSelectAllVisible,
                    onTag: {
                        batchPeopleInput = ""
                        isBatchTagSheetPresented = true
                    },
                    onDelete: {
                        isDeleteConfirmationPresented = true
                    }
                )
            }
        }
        .fullScreenCover(item: $previewMemory) { memory in
            MemoryPhotoPagerView(
                memories: filteredMemories,
                initialMemoryID: memory.id,
                fileStore: fileStore,
                onOpenDetails: { selectedMemory in
                    previewMemory = nil
                    DispatchQueue.main.async {
                        onOpenMemory(selectedMemory)
                    }
                }
            )
        }
        .sheet(isPresented: $isBatchTagSheetPresented) {
            AlbumBatchTagSheet(
                selectedCount: selectedMemoryIDs.count,
                peopleInput: $batchPeopleInput,
                onApply: applyBatchPeopleTags
            )
        }
        .confirmationDialog(
            "album.delete.confirmation.title",
            isPresented: $isDeleteConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button("album.deleteSelected", role: .destructive) {
                deleteSelectedMemories()
            }
            .disabled(selectedMemoryIDs.isEmpty)

            Button("common.cancel", role: .cancel) {}
        } message: {
            Text("album.delete.confirmation.message")
        }
        .alert("common.error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if $0 == false { errorMessage = nil } }
        )) {
            Button("common.ok", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
        .task(id: reloadToken) {
            await viewModel.load()
        }
    }

    private var albumContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                MemoryFilterBar(
                    filter: $filter,
                    years: availableYears,
                    people: availablePeople,
                    onReset: clearFilters
                )
                .padding(.horizontal)

                if filteredMemories.isEmpty {
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
                    .frame(maxWidth: .infinity)
                    .padding(.top, 70)
                } else {
                    LazyVStack(alignment: .leading, spacing: 22) {
                        ForEach(filteredSections) { section in
                            VStack(alignment: .leading, spacing: 10) {
                                Text("\(section.year).\(String(format: "%02d", section.month))")
                                    .font(.headline)
                                    .padding(.horizontal)

                                LazyVGrid(columns: columns, spacing: 8) {
                                    ForEach(section.memories) { memory in
                                        Button {
                                            handleMemoryTap(memory)
                                        } label: {
                                            AlbumMemoryTile(
                                                memory: memory,
                                                imageURL: fileStore.url(forRelativePath: memory.thumbnailPath),
                                                isSelectionMode: isSelectionMode,
                                                isSelected: selectedMemoryIDs.contains(memory.id)
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
            }
            .padding(.vertical)
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

    private var visibleMemoryIDs: Set<String> {
        Set(filteredMemories.map(\.id))
    }

    private var allVisibleSelected: Bool {
        visibleMemoryIDs.isEmpty == false && visibleMemoryIDs.isSubset(of: selectedMemoryIDs)
    }

    private func handleMemoryTap(_ memory: FamilyMemory) {
        if isSelectionMode {
            if selectedMemoryIDs.contains(memory.id) {
                selectedMemoryIDs.remove(memory.id)
            } else {
                selectedMemoryIDs.insert(memory.id)
            }
        } else {
            previewMemory = memory
        }
    }

    private func toggleSelectionMode() {
        isSelectionMode.toggle()
        if isSelectionMode == false {
            selectedMemoryIDs.removeAll()
        }
    }

    private func toggleSelectAllVisible() {
        if allVisibleSelected {
            selectedMemoryIDs.subtract(visibleMemoryIDs)
        } else {
            selectedMemoryIDs.formUnion(visibleMemoryIDs)
        }
    }

    private func clearFilters() {
        filter = AlbumFilterState()
    }

    private func deleteSelectedMemories() {
        let memoriesToDelete = allMemories.filter { selectedMemoryIDs.contains($0.id) }

        do {
            for memory in memoriesToDelete {
                try repository.delete(id: memory.id)
                try? fileStore.deleteMemoryFiles(
                    originalRelativePath: memory.originalPath,
                    thumbnailRelativePath: memory.thumbnailPath
                )
            }

            selectedMemoryIDs.removeAll()
            isSelectionMode = false
            onChange()
            Task {
                await viewModel.load()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func applyBatchPeopleTags() {
        let tags = PeopleTagNormalizer.normalizeText(batchPeopleInput)
        guard tags.isEmpty == false else { return }

        let memoriesToUpdate = allMemories.filter { selectedMemoryIDs.contains($0.id) }

        do {
            for var memory in memoriesToUpdate {
                memory.people = PeopleTagNormalizer.merge(existing: memory.people, adding: tags)
                memory.updatedAt = Date()
                try repository.save(memory)
            }

            batchPeopleInput = ""
            selectedMemoryIDs.removeAll()
            isSelectionMode = false
            isBatchTagSheetPresented = false
            onChange()
            Task {
                await viewModel.load()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct AlbumSelectionBar: View {
    let selectedCount: Int
    let allVisibleSelected: Bool
    let canSelectVisible: Bool
    let onToggleSelectAll: () -> Void
    let onTag: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text("album.selected.label")
                .font(.subheadline)
            Text(verbatim: String(selectedCount))
                .font(.subheadline.weight(.semibold))

            Spacer()

            Button(allVisibleSelected ? "album.clearSelection" : "album.selectAll") {
                onToggleSelectAll()
            }
            .disabled(canSelectVisible == false)

            Button(action: onTag) {
                Label("album.addTags", systemImage: "tag")
            }
            .disabled(selectedCount == 0)

            Button(role: .destructive, action: onDelete) {
                Label("album.deleteSelected", systemImage: "trash")
            }
            .disabled(selectedCount == 0)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.bar)
    }
}

private struct AlbumBatchTagSheet: View {
    @Environment(\.dismiss) private var dismiss

    let selectedCount: Int
    @Binding var peopleInput: String
    let onApply: () -> Void

    private var normalizedPeople: [String] {
        PeopleTagNormalizer.normalizeText(peopleInput)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("album.batchTag.placeholder", text: $peopleInput, axis: .vertical)
                        .lineLimit(2...4)

                    Text("album.batchTag.helper")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("album.batchTag.section")
                }

                Section {
                    LabeledContent("album.selected.label") {
                        Text(verbatim: String(selectedCount))
                    }
                }
            }
            .navigationTitle("album.batchTag.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("album.batchTag.apply") {
                        onApply()
                    }
                    .disabled(normalizedPeople.isEmpty || selectedCount == 0)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

private struct AlbumMemoryTile: View {
    let memory: FamilyMemory
    let imageURL: URL
    let isSelectionMode: Bool
    let isSelected: Bool

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            MemoryThumbnailView(imageURL: imageURL, size: nil, cornerRadius: 8)
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fill)

            LinearGradient(
                colors: [.clear, .black.opacity(0.62)],
                startPoint: .center,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(memory.date, style: .date)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white)

                if memory.people.isEmpty == false {
                    Text(memory.people.joined(separator: " · "))
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.86))
                        .lineLimit(1)
                }
            }
            .padding(8)

            if isSelectionMode {
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(isSelected ? .white : .secondary, isSelected ? .blue : .white)
                            .background(.thinMaterial, in: Circle())
                    }
                    Spacer()
                }
                .padding(8)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: Text {
        if memory.story.isEmpty {
            Text(memory.date, style: .date)
        } else {
            Text(verbatim: memory.story)
        }
    }
}
