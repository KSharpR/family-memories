import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct AppRootView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("app.language") private var languageID = AppLanguage.chinese.rawValue
    @State private var environment: AppEnvironment?
    @State private var selectedMemory: FamilyMemory?
    @State private var presentedDrafts: [MemoryDraft] = []
    @State private var timelineReloadToken = UUID()
    @State private var environmentError: String?
    @State private var exportedBackup: ExportedBackup?
    @State private var isImportingBackup = false
    @State private var backupAlert: BackupAlert?

    var body: some View {
        Group {
            if let environment {
                TabView {
                    NavigationStack {
                        TimelineView(
                            repository: environment.repository,
                            fileStore: environment.fileStore,
                            importService: environment.importService,
                            reloadToken: timelineReloadToken,
                            onImportedDrafts: { drafts in
                                presentedDrafts = drafts
                            },
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
                        .sheet(isPresented: Binding(
                            get: { presentedDrafts.isEmpty == false },
                            set: { if $0 == false { presentedDrafts = [] } }
                        )) {
                            ImportReviewView(
                                drafts: presentedDrafts,
                                repository: environment.repository,
                                onSave: {
                                    presentedDrafts = []
                                    reloadTimeline()
                                }
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
                        SettingsView(
                            language: languageBinding,
                            onExportBackup: {
                                exportBackup(using: environment)
                            },
                            onImportBackup: {
                                isImportingBackup = true
                            }
                        )
                        .id(language.id)
                    }
                    .tabItem {
                        Label("tab.settings", systemImage: "gearshape")
                    }
                }
                .sheet(item: $exportedBackup) { backup in
                    NavigationStack {
                        VStack(spacing: 18) {
                            Image(systemName: "archivebox")
                                .font(.system(size: 44))
                                .foregroundStyle(.secondary)

                            Text("settings.export.ready.body")
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.secondary)

                            ShareLink(item: backup.url) {
                                Label("settings.exportBackup", systemImage: "square.and.arrow.up")
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                        .navigationTitle("settings.export.ready.title")
                        .toolbar {
                            Button("common.done") {
                                exportedBackup = nil
                            }
                        }
                    }
                    .presentationDetents([.medium])
                }
                .fileImporter(
                    isPresented: $isImportingBackup,
                    allowedContentTypes: [.familyMemoriesBackup],
                    allowsMultipleSelection: false
                ) { result in
                    importBackup(result, using: environment)
                }
                .alert(item: $backupAlert) { alert in
                    switch alert {
                    case let .message(title, message):
                        Alert(
                            title: Text(title),
                            message: Text(message),
                            dismissButton: .default(Text("common.ok"))
                        )
                    case let .error(message):
                        Alert(
                            title: Text("common.error"),
                            message: Text(message),
                            dismissButton: .default(Text("common.ok"))
                        )
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
        .environment(\.locale, language.locale)
    }

    private var language: AppLanguage {
        AppLanguage(rawValue: languageID) ?? .chinese
    }

    private var languageBinding: Binding<AppLanguage> {
        Binding(
            get: { language },
            set: { languageID = $0.rawValue }
        )
    }

    private func loadEnvironment() {
        do {
            if ProcessInfo.processInfo.arguments.contains("-ui-testing")
                && ProcessInfo.processInfo.arguments.contains("-reset-data") {
                languageID = AppLanguage.chinese.rawValue
            }
            environment = try AppEnvironment(modelContext: modelContext)
            environmentError = nil
        } catch {
            environmentError = error.localizedDescription
        }
    }

    private func reloadTimeline() {
        timelineReloadToken = UUID()
    }

    private func exportBackup(using environment: AppEnvironment) {
        Task {
            do {
                let memories = try await environment.repository.fetchAll()
                let backupURL = try environment.backupService.exportBackup(
                    memories: memories,
                    localeIdentifier: language.rawValue
                )
                exportedBackup = ExportedBackup(url: backupURL)
            } catch {
                backupAlert = .error(error.localizedDescription)
            }
        }
    }

    private func importBackup(_ result: Result<[URL], Error>, using environment: AppEnvironment) {
        do {
            let urls = try result.get()
            guard let url = urls.first else { return }

            let didStartAccessing = url.startAccessingSecurityScopedResource()
            defer {
                if didStartAccessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            _ = try environment.backupService.validateBackup(at: url)
            backupAlert = .message(
                title: "settings.import.valid.title",
                message: "settings.import.valid.body"
            )
        } catch let error as CocoaError where error.code == .userCancelled {
            return
        } catch let error where isInvalidBackupImportError(error) {
            backupAlert = .message(
                title: "settings.import.invalid.title",
                message: "settings.import.invalid.body"
            )
        } catch {
            backupAlert = .error(error.localizedDescription)
        }
    }

    private func isInvalidBackupImportError(_ error: Error) -> Bool {
        error is BackupPackageError
            || error is DecodingError
            || error is MemoryFileStoreError
    }
}

private struct ExportedBackup: Identifiable {
    let url: URL

    var id: String { url.absoluteString }
}

private enum BackupAlert: Identifiable {
    case message(title: LocalizedStringKey, message: LocalizedStringKey)
    case error(String)

    var id: String {
        switch self {
        case let .message(title, message):
            return "\(title)-\(message)"
        case let .error(message):
            return message
        }
    }
}

#Preview {
    AppRootView()
        .modelContainer(for: MemoryRecord.self, inMemory: true)
}
