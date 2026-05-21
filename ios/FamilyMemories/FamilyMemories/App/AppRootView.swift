import SwiftUI

struct AppRootView: View {
    var body: some View {
        TabView {
            NavigationStack {
                Text("timeline.empty.title")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .tabItem {
                Label("tab.timeline", systemImage: "clock")
            }

            NavigationStack {
                Text("album.empty.title")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .tabItem {
                Label("tab.album", systemImage: "book.pages")
            }

            NavigationStack {
                Text("settings.title")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .tabItem {
                Label("tab.settings", systemImage: "gearshape")
            }
        }
    }
}

#Preview {
    AppRootView()
}
