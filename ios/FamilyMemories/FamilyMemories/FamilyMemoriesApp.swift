import SwiftData
import SwiftUI

@main
struct FamilyMemoriesApp: App {
    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
        .modelContainer(for: MemoryRecord.self)
    }
}
