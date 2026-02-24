import SwiftData
import SwiftUI

private enum MacSidebarItem: String, CaseIterable, Identifiable {
    case timer
    case history
    case settings

    var id: String {
        self.rawValue
    }

    var title: String {
        switch self {
        case .timer:
            "Timer"
        case .history:
            "History"
        case .settings:
            "Settings"
        }
    }

    var symbolName: String {
        switch self {
        case .timer:
            "timer"
        case .history:
            "clock.arrow.circlepath"
        case .settings:
            "gearshape"
        }
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    @State private var store = TimerStore()

    var body: some View {
        Group {
            #if os(macOS)
                self.macLayout
            #else
                self.iosLayout
            #endif
        }
        .task {
            self.store.bind(modelContext: self.modelContext)
        }
        .onChange(of: self.scenePhase) { _, newPhase in
            self.store.handleScenePhaseChange(newPhase)
        }
    }

    #if os(macOS)
        @State private var selectedSidebarItem: MacSidebarItem = .timer

        private var macLayout: some View {
            NavigationSplitView {
                List(MacSidebarItem.allCases, selection: self.$selectedSidebarItem) { item in
                    Label(item.title, systemImage: item.symbolName)
                        .tag(item)
                }
                .navigationTitle("Kokukoku")
                .listStyle(.sidebar)
                .frame(minWidth: 200)
            } detail: {
                switch self.selectedSidebarItem {
                case .timer:
                    NavigationStack {
                        TimerScreen(store: self.store)
                    }
                case .history:
                    NavigationStack {
                        HistoryScreen()
                    }
                case .settings:
                    NavigationStack {
                        SettingsScreen(store: self.store)
                    }
                }
            }
            .frame(minWidth: 900, minHeight: 600)
        }
    #else
        private var iosLayout: some View {
            NavigationStack {
                TimerScreen(store: self.store)
                    .toolbar {
                        ToolbarItemGroup(placement: .topBarTrailing) {
                            NavigationLink {
                                HistoryScreen()
                            } label: {
                                Image(systemName: "clock.arrow.circlepath")
                            }

                            NavigationLink {
                                SettingsScreen(store: self.store)
                            } label: {
                                Image(systemName: "gearshape")
                            }
                        }
                    }
            }
        }
    #endif
}

#Preview {
    ContentView()
        .modelContainer(for: [SessionRecord.self, UserTimerPreferences.self], inMemory: true)
}
