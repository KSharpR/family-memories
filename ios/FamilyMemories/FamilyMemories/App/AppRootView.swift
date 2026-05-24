import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct AppRootView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("app.language") private var languageID = AppLanguage.chinese.rawValue
    @State private var environment: AppEnvironment?
    @State private var selectedMemory: FamilyMemory?
    @State private var presentedImportResult: PhotoImportResult?
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
                            onImportResult: { result in
                                presentedImportResult = result
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
                            get: { presentedImportResult != nil },
                            set: { if $0 == false { presentedImportResult = nil } }
                        )) {
                            ImportReviewView(
                                drafts: presentedImportResult?.drafts ?? [],
                                failures: presentedImportResult?.failures ?? [],
                                repository: environment.repository,
                                onSave: {
                                    presentedImportResult = nil
                                    reloadTimeline()
                                }
                            )
                        }
                    }
                    .tabItem {
                        Label("tab.timeline", systemImage: "clock")
                    }

                    NavigationStack {
                        AlbumView(
                            repository: environment.repository,
                            fileStore: environment.fileStore,
                            reloadToken: timelineReloadToken,
                            onOpenMemory: { selectedMemory = $0 },
                            onChange: reloadTimeline
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
                        Label("tab.album", systemImage: "book.pages")
                    }

                    NavigationStack {
                        SettingsView(
                            language: languageBinding,
                            storageUsageService: environment.storageUsageService,
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
                    case let .confirm(request):
                        Alert(
                            title: Text("settings.import.confirm.title"),
                            message: importConfirmationMessage(for: request),
                            primaryButton: .default(Text("settings.import.confirm.action")) {
                                confirmBackupImport(request, using: environment)
                            },
                            secondaryButton: .cancel(Text("common.cancel"))
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

            let summary = try environment.backupService.validateBackup(at: url)
            backupAlert = .confirm(BackupImportRequest(url: url, summary: summary))
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

    private func importConfirmationMessage(for request: BackupImportRequest) -> Text {
        let summaryText = BackupImportConfirmationFormatter.summaryText(
            for: request.summary,
            locale: language.locale
        )

        return Text("settings.import.confirm.body")
            + Text(verbatim: "\n\n")
            + Text("settings.import.confirm.memoryCount")
            + Text(verbatim: " \(summaryText.memoryCount)")
            + Text(verbatim: "\n")
            + Text("settings.import.confirm.createdAt")
            + Text(verbatim: " \(summaryText.createdAt)")
    }

    private func confirmBackupImport(_ request: BackupImportRequest, using environment: AppEnvironment) {
        do {
            let didStartAccessing = request.url.startAccessingSecurityScopedResource()
            defer {
                if didStartAccessing {
                    request.url.stopAccessingSecurityScopedResource()
                }
            }

            let result = try environment.backupService.restoreBackup(at: request.url)
            for memory in result.memories {
                try environment.repository.save(memory)
            }
            reloadTimeline()
            backupAlert = .message(
                title: "settings.import.restored.title",
                message: "settings.import.restored.body"
            )
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

struct BackupImportConfirmationSummaryText: Equatable {
    let memoryCount: String
    let createdAt: String
}

enum BackupImportConfirmationFormatter {
    static func summaryText(
        for summary: BackupSummary,
        locale: Locale,
        timeZone: TimeZone = .current
    ) -> BackupImportConfirmationSummaryText {
        let numberFormatter = NumberFormatter()
        numberFormatter.locale = locale
        numberFormatter.numberStyle = .decimal

        let dateFormatter = DateFormatter()
        dateFormatter.locale = locale
        dateFormatter.timeZone = timeZone
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short

        return BackupImportConfirmationSummaryText(
            memoryCount: numberFormatter.string(from: NSNumber(value: summary.memoryCount)) ?? "\(summary.memoryCount)",
            createdAt: dateFormatter.string(from: summary.createdAt)
        )
    }
}

private struct ExportedBackup: Identifiable {
    let url: URL

    var id: String { url.absoluteString }
}

private struct BackupImportRequest: Identifiable {
    let url: URL
    let summary: BackupSummary

    var id: String {
        "\(url.absoluteString)-\(summary.createdAt.timeIntervalSince1970)-\(summary.memoryCount)"
    }
}

private enum BackupAlert: Identifiable {
    case message(title: LocalizedStringKey, message: LocalizedStringKey)
    case error(String)
    case confirm(BackupImportRequest)

    var id: String {
        switch self {
        case let .message(title, message):
            return "\(title)-\(message)"
        case let .error(message):
            return message
        case let .confirm(request):
            return request.id
        }
    }
}

#Preview {
    AppRootView()
        .modelContainer(for: MemoryRecord.self, inMemory: true)
}
