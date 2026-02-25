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
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    @State private var hasDismissedLaunchOverlay = false
    @Bindable var store: TimerStore

    var body: some View {
        Group {
            #if os(macOS)
                self.macLayout
            #else
                self.iosLayout
            #endif
        }
        .overlay {
            if !self.hasDismissedLaunchOverlay, !self.isRunningInPreview {
                LaunchOverlayView(isHighContrast: self.colorSchemeContrast == .increased)
                    .transition(self.accessibilityReduceMotion ? .identity : .opacity)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
        .task {
            self.store.bind(modelContext: self.modelContext)

            if self.isRunningInPreview {
                self.hasDismissedLaunchOverlay = true
                return
            }

            await self.dismissLaunchOverlayIfNeeded()
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
                            .accessibilityLabel("History")
                            .accessibilityIdentifier("nav.history")

                            NavigationLink {
                                SettingsScreen(store: self.store)
                            } label: {
                                Image(systemName: "gearshape")
                            }
                            .accessibilityLabel("Settings")
                            .accessibilityIdentifier("nav.settings")
                        }
                    }
            }
        }
    #endif

    private func dismissLaunchOverlayIfNeeded() async {
        guard !self.hasDismissedLaunchOverlay else {
            return
        }

        let delayNanoseconds: UInt64 = self.accessibilityReduceMotion ? 150_000_000 : 450_000_000
        try? await Task.sleep(nanoseconds: delayNanoseconds)

        if self.accessibilityReduceMotion {
            self.hasDismissedLaunchOverlay = true
        } else {
            withAnimation(.easeOut(duration: 0.25)) {
                self.hasDismissedLaunchOverlay = true
            }
        }
    }

    private var isRunningInPreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
}

#Preview {
    ContentView(store: TimerStore())
        .modelContainer(for: [SessionRecord.self, UserTimerPreferences.self], inMemory: true)
}

private struct LaunchOverlayView: View {
    let isHighContrast: Bool

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.background)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                Image(systemName: "timer")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(.primary)

                Text("Kokukoku")
                    .font(.title3.weight(.semibold))

                Text("Pomodoro Timer")
                    .font(.footnote)
                    .foregroundStyle(self.isHighContrast ? .primary : .secondary)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
    }
}
