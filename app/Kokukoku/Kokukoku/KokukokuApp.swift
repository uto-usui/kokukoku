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
        WindowGroup(id: "main") {
            ContentView(store: self.store)
        }
        .modelContainer(self.sharedModelContainer)

        #if os(macOS)
            MenuBarExtra {
                MenuBarTimerView(store: self.store)
            } label: {
                Label(self.store.formattedRemainingTime, systemImage: self.store.sessionType.symbolName)
            }
            .menuBarExtraStyle(.window)
            .modelContainer(self.sharedModelContainer)
        #endif
    }
}
