import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    @Namespace private var sheetTransition
    @State private var hasDismissedLaunchOverlay = false
    @State private var showHistory = false
    @State private var showSettings = false
    @Bindable var store: TimerStore

    var body: some View {
        NavigationStack {
            TimerScreen(store: self.store)
                .toolbar {
                    #if os(macOS)
                        ToolbarItem(placement: .primaryAction) {
                            self.ellipsisMenu
                        }
                    #else
                        ToolbarItem(placement: .topBarTrailing) {
                            self.ellipsisMenu
                        }
                    #endif
                }
                .sheet(isPresented: self.$showHistory) {
                    self.historySheet
                }
                .sheet(isPresented: self.$showSettings) {
                    self.settingsSheet
                }
            #if os(macOS)
                .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
            #else
                .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
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

    // MARK: - Menu

    private var ellipsisMenu: some View {
        Menu {
            Toggle(
                isOn: Binding(
                    get: { self.store.config.ambientNoiseEnabled },
                    set: { self.store.updateAmbientNoiseEnabled($0) }
                )
            ) {
                Label("Sound", systemImage: "speaker.wave.2")
            }

            Button {
                self.showHistory = true
            } label: {
                Label("History", systemImage: "clock.arrow.circlepath")
            }

            Button {
                self.showSettings = true
            } label: {
                Label("Settings\u{2026}", systemImage: "gearshape")
            }
        } label: {
            Image(systemName: "ellipsis")
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
        #if os(iOS)
            .matchedTransitionSource(id: "systemMenu", in: self.sheetTransition)
        #endif
            .accessibilityLabel("Menu")
            .accessibilityIdentifier("nav.system")
    }

    // MARK: - Sheets

    private var historySheet: some View {
        NavigationStack {
            HistoryScreen()
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("", systemImage: "xmark") {
                            self.showHistory = false
                        }
                    }
                }
        }
        #if os(iOS)
        .navigationTransition(
            .zoom(sourceID: "systemMenu", in: self.sheetTransition)
        )
        #endif
    }

    private var settingsSheet: some View {
        NavigationStack {
            SettingsScreen(store: self.store)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("", systemImage: "xmark") {
                            self.showSettings = false
                        }
                    }
                }
        }
        #if os(iOS)
        .navigationTransition(
            .zoom(sourceID: "systemMenu", in: self.sheetTransition)
        )
        #endif
    }

    // MARK: - Launch Overlay

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

                Text(verbatim: "Kokukoku")
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
