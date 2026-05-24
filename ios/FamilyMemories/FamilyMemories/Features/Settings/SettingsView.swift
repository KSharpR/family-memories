import SwiftUI

struct SettingsView: View {
    @Binding var language: AppLanguage
    @State private var storageUsage: StorageUsage?
    @State private var storageUsageError: String?

    let storageUsageService: StorageUsageService
    let onExportBackup: () -> Void
    let onImportBackup: () -> Void

    var body: some View {
        Form {
            Section("settings.language") {
                Picker("settings.language", selection: $language) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.displayName).tag(language)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("settings.backup") {
                Button(action: onExportBackup) {
                    Label("settings.exportBackup", systemImage: "square.and.arrow.up")
                }

                Button(action: onImportBackup) {
                    Label("settings.importBackup", systemImage: "square.and.arrow.down")
                }

                Text("settings.backup.reminder")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("settings.storage") {
                if let storageUsage {
                    LabeledContent("settings.storage.total") {
                        Text(verbatim: formattedBytes(storageUsage.totalBytes))
                    }

                    LabeledContent("settings.storage.originals") {
                        Text(verbatim: formattedBytes(storageUsage.originalsBytes))
                    }

                    LabeledContent("settings.storage.thumbnails") {
                        Text(verbatim: formattedBytes(storageUsage.thumbnailsBytes))
                    }

                    LabeledContent("settings.storage.backups") {
                        Text(verbatim: formattedBytes(storageUsage.backupsBytes))
                    }

                    LabeledContent("settings.storage.metadata") {
                        Text(verbatim: formattedBytes(storageUsage.metadataBytes))
                    }
                } else if let storageUsageError {
                    Text(verbatim: storageUsageError)
                        .foregroundStyle(.secondary)
                } else {
                    ProgressView()
                }

                Text("settings.storage.privacy.body")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("settings.privacy") {
                Text("settings.privacy.body")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("settings.title")
        .task {
            loadStorageUsage()
        }
    }

    private func loadStorageUsage() {
        do {
            storageUsage = try storageUsageService.calculateUsage()
            storageUsageError = nil
        } catch {
            storageUsage = nil
            storageUsageError = error.localizedDescription
        }
    }

    private func formattedBytes(_ byteCount: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: byteCount, countStyle: .file)
    }
}

#Preview {
    @Previewable @State var language: AppLanguage = .chinese
    let previewStore = try! MemoryFileStore(
        rootURL: FileManager.default.temporaryDirectory
            .appendingPathComponent("FamilyMemoriesSettingsPreview", isDirectory: true)
    )

    NavigationStack {
        SettingsView(
            language: $language,
            storageUsageService: StorageUsageService(fileStore: previewStore),
            onExportBackup: {},
            onImportBackup: {}
        )
    }
}
