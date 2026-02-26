import SwiftData
import SwiftUI

@main
struct KokukokuApp: App {
    @State private var store = TimerStore()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            SessionRecord.self,
            UserTimerPreferences.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        #if os(macOS)
            Window("Kokukoku", id: "main") {
                ContentView(store: self.store)
            }
            .modelContainer(self.sharedModelContainer)
            .defaultSize(width: 380, height: 640)
            .windowResizability(.contentMinSize)

            MenuBarExtra {
                MenuBarTimerView(store: self.store)
            } label: {
                Label(self.store.formattedRemainingTime, systemImage: self.store.sessionType.symbolName)
            }
            .menuBarExtraStyle(.window)
            .modelContainer(self.sharedModelContainer)

            Settings {
                SettingsScreen(store: self.store)
                    .modelContainer(self.sharedModelContainer)
            }
        #else
            WindowGroup {
                ContentView(store: self.store)
            }
            .modelContainer(self.sharedModelContainer)
        #endif
    }
}
