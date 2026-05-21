import SwiftUI

struct TimelineView: View {
    @StateObject private var viewModel: TimelineViewModel

    let fileStore: MemoryFileStore
    let reloadToken: UUID
    let onImport: () -> Void
    let onOpenMemory: (FamilyMemory) -> Void

    init(
        repository: MemoryRepositoryProtocol,
        fileStore: MemoryFileStore,
        reloadToken: UUID,
        onImport: @escaping () -> Void,
        onOpenMemory: @escaping (FamilyMemory) -> Void
    ) {
        _viewModel = StateObject(wrappedValue: TimelineViewModel(repository: repository))
        self.fileStore = fileStore
        self.reloadToken = reloadToken
        self.onImport = onImport
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
                    Button("timeline.import", action: onImport)
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

                                            Text(memory.story.isEmpty ? String(localized: "memory.story.empty") : memory.story)
                                                .font(.body)
                                                .foregroundStyle(.primary)
                                                .lineLimit(2)

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
            Button(action: onImport) {
                Label("timeline.import", systemImage: "plus")
            }
        }
        .task(id: reloadToken) {
            await viewModel.load()
        }
    }
}
