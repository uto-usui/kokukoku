import SwiftUI

@main
struct KokukokuWatchApp: App {
    @State private var store = WatchSessionStore()

    var body: some Scene {
        WindowGroup {
            WatchTimerScreen(store: self.store)
                .task {
                    self.store.bind()
                }
        }
    }
}

struct WatchTimerScreen: View {
    @Bindable var store: WatchSessionStore

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                Text(self.store.sessionTypeTitle)
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text(self.store.formattedRemainingTime)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .monospacedDigit()

                Text(self.store.cycleText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Button(self.store.primaryActionTitle) {
                    self.store.sendPrimaryAction()
                }
                .buttonStyle(.borderedProminent)

                HStack(spacing: 8) {
                    Button("Reset") {
                        self.store.sendReset()
                    }
                    .buttonStyle(.bordered)

                    Button("Skip") {
                        self.store.sendSkip()
                    }
                    .buttonStyle(.bordered)
                }

                Text(self.store.boundaryStopPolicyTitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Text(self.store.isReachable ? "Connected" : "Waiting for iPhone")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                if let lastErrorMessage = self.store.lastErrorMessage {
                    Text(lastErrorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
    }
}
