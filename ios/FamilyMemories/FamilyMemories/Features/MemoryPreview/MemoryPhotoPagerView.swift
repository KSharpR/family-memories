import SwiftUI
import UIKit

struct MemoryPhotoPagerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMemoryID: String

    let memories: [FamilyMemory]
    let fileStore: MemoryFileStore
    let onOpenDetails: ((FamilyMemory) -> Void)?

    init(
        memories: [FamilyMemory],
        initialMemoryID: String,
        fileStore: MemoryFileStore,
        onOpenDetails: ((FamilyMemory) -> Void)? = nil
    ) {
        self.memories = memories
        self.fileStore = fileStore
        self.onOpenDetails = onOpenDetails
        _selectedMemoryID = State(initialValue: initialMemoryID)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if memories.isEmpty {
                    ContentUnavailableView("album.filter.empty.title", systemImage: "photo")
                        .foregroundStyle(.white)
                } else {
                    TabView(selection: $selectedMemoryID) {
                        ForEach(memories) { memory in
                            MemoryPhotoPreviewPage(
                                memory: memory,
                                imageURL: fileStore.url(forRelativePath: memory.originalPath)
                            )
                            .tag(memory.id)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: memories.count > 1 ? .automatic : .never))
                }
            }
            .navigationTitle("album.preview.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(.black, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.done") {
                        dismiss()
                    }
                }

                if let onOpenDetails, let selectedMemory {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("album.preview.openDetail") {
                            dismiss()
                            onOpenDetails(selectedMemory)
                        }
                    }
                }
            }
        }
    }

    private var selectedMemory: FamilyMemory? {
        memories.first { $0.id == selectedMemoryID } ?? memories.first
    }
}

private struct MemoryPhotoPreviewPage: View {
    let memory: FamilyMemory
    let imageURL: URL

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                fullImage
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 420)

                VStack(alignment: .leading, spacing: 14) {
                    LabeledContent("memory.date") {
                        Text(memory.date, style: .date)
                    }

                    if memory.people.isEmpty == false {
                        LabeledContent("memory.people") {
                            Text(verbatim: memory.people.joined(separator: " · "))
                        }
                    }

                    Divider()
                        .overlay(.white.opacity(0.25))

                    VStack(alignment: .leading, spacing: 8) {
                        Text("memory.story")
                            .font(.headline)

                        if memory.story.isEmpty {
                            Text("memory.story.empty")
                                .foregroundStyle(.secondary)
                        } else {
                            Text(verbatim: memory.story)
                        }
                    }
                }
                .font(.body)
                .foregroundStyle(.white)
                .padding(.horizontal)
                .padding(.bottom, 34)
            }
            .padding(.top, 8)
        }
    }

    @ViewBuilder
    private var fullImage: some View {
        if let image = UIImage(contentsOfFile: imageURL.path) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
        } else {
            ZStack {
                Rectangle().fill(.white.opacity(0.08))
                Image(systemName: "photo")
                    .font(.system(size: 44))
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
    }
}
