import SwiftUI

struct SettingsView: View {
    @Binding var language: AppLanguage

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

            Section("settings.privacy") {
                Text("settings.privacy.body")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("settings.title")
    }
}

#Preview {
    @Previewable @State var language: AppLanguage = .chinese

    NavigationStack {
        SettingsView(
            language: $language,
            onExportBackup: {},
            onImportBackup: {}
        )
    }
}
