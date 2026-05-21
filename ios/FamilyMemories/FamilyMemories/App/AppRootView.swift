import SwiftData
import SwiftUI

struct AppRootView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var environment: AppEnvironment?
    @State private var selectedMemory: FamilyMemory?
    @State private var timelineReloadToken = UUID()
    @State private var environmentError: String?

    var body: some View {
        Group {
            if let environment {
                TabView {
                    NavigationStack {
                        TimelineView(
                            repository: environment.repository,
                            fileStore: environment.fileStore,
                            reloadToken: timelineReloadToken,
                            onImport: {},
                            onOpenMemory: { selectedMemory = $0 }
                        )
                        .navigationDestination(item: $selectedMemory) { memory in
                            MemoryDetailView(
                                memory: memory,
                                repository: environment.repository,
                                fileStore: environment.fileStore,
                                onChange: reloadTimeline
                            )
                        }
                    }
                    .tabItem {
                        Label("tab.timeline", systemImage: "clock")
                    }

                    NavigationStack {
                        ContentUnavailableView("album.empty.title", systemImage: "book.pages")
                    }
                    .tabItem {
                        Label("tab.album", systemImage: "book.pages")
                    }

                    NavigationStack {
                        Form {
                            Section {
                                Text("settings.title")
                                    .font(.headline)
                            }
                        }
                        .navigationTitle("settings.title")
                    }
                    .tabItem {
                        Label("tab.settings", systemImage: "gearshape")
                    }
                }
            } else if let environmentError {
                ContentUnavailableView {
                    Label("app.startup.error", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(environmentError)
                } actions: {
                    Button("common.retry") {
                        loadEnvironment()
                    }
                    .buttonStyle(.bordered)
                }
            } else {
                ProgressView()
                    .task {
                        loadEnvironment()
                    }
            }
        }
    }

    private func loadEnvironment() {
        do {
            environment = try AppEnvironment(modelContext: modelContext)
            environmentError = nil
        } catch {
            environmentError = error.localizedDescription
        }
    }

    private func reloadTimeline() {
        timelineReloadToken = UUID()
    }
}

#Preview {
    AppRootView()
        .modelContainer(for: MemoryRecord.self, inMemory: true)
}
