import SwiftUI

struct AlbumView: View {
    @StateObject private var viewModel: TimelineViewModel

    let fileStore: MemoryFileStore
    let reloadToken: UUID
    let onOpenMemory: (FamilyMemory) -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 108, maximum: 180), spacing: 8)
    ]

    init(
        repository: MemoryRepositoryProtocol,
        fileStore: MemoryFileStore,
        reloadToken: UUID,
        onOpenMemory: @escaping (FamilyMemory) -> Void
    ) {
        _viewModel = StateObject(wrappedValue: TimelineViewModel(repository: repository))
        self.fileStore = fileStore
        self.reloadToken = reloadToken
        self.onOpenMemory = onOpenMemory
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
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 22) {
                        ForEach(viewModel.sections) { section in
                            VStack(alignment: .leading, spacing: 10) {
                                Text("\(section.year).\(String(format: "%02d", section.month))")
                                    .font(.headline)
                                    .padding(.horizontal)

                                LazyVGrid(columns: columns, spacing: 8) {
                                    ForEach(section.memories) { memory in
                                        Button {
                                            onOpenMemory(memory)
                                        } label: {
                                            AlbumMemoryTile(
                                                memory: memory,
                                                imageURL: fileStore.url(forRelativePath: memory.thumbnailPath)
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
        }
        .navigationTitle("tab.album")
        .task(id: reloadToken) {
            await viewModel.load()
        }
    }
}

private struct AlbumMemoryTile: View {
    let memory: FamilyMemory
    let imageURL: URL

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
