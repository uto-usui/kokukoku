import SwiftUI

struct TimerScreen: View {
    @Bindable var store: TimerStore

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                self.sessionHeader
                self.timerDisplay
                self.progressDisplay
                self.controlButtons
                self.boundaryStopControls
                self.statusFooter
            }
            .padding(24)
            .frame(maxWidth: 680)
        }
        .navigationTitle("Kokukoku")
    }

    private var sessionHeader: some View {
        Label(self.store.sessionType.title, systemImage: self.store.sessionType.symbolName)
            .font(.title3.weight(.medium))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.thinMaterial, in: Capsule())
    }

    private var timerDisplay: some View {
        Text(self.store.formattedRemainingTime)
            .font(.system(size: 74, weight: .bold, design: .rounded))
            .monospacedDigit()
            .accessibilityLabel("Remaining time \(self.store.formattedRemainingTime)")
            .accessibilityIdentifier("timer.remaining")
    }

    private var progressDisplay: some View {
        VStack(spacing: 8) {
            ProgressView(value: self.store.progress)
                .progressViewStyle(.linear)
            Text(self.store.focusCycleStatusText)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var controlButtons: some View {
        VStack(spacing: 12) {
            Button(self.store.primaryActionTitle) {
                self.store.performPrimaryAction()
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("timer.primaryAction")

            HStack(spacing: 10) {
                Button("Reset") {
                    self.store.reset()
                }
                .buttonStyle(.bordered)
                .disabled(!self.store.canReset)
                .accessibilityIdentifier("timer.reset")

                Button("Skip") {
                    self.store.skip()
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("timer.skip")
            }
        }
    }

    private var boundaryStopControls: some View {
        VStack(spacing: 10) {
            Toggle(
                "Stop at next boundary",
                isOn: Binding(
                    get: { self.store.boundaryStopPolicy == .stopAtNextBoundary },
                    set: { newValue in
                        self.store.setBoundaryStopPolicy(newValue ? .stopAtNextBoundary : .none)
                    }
                )
            )

            Toggle(
                "Stop at long break",
                isOn: Binding(
                    get: { self.store.boundaryStopPolicy == .stopAtLongBreak },
                    set: { newValue in
                        self.store.setBoundaryStopPolicy(newValue ? .stopAtLongBreak : .none)
                    }
                )
            )
        }
        .toggleStyle(.switch)
    }

    private var statusFooter: some View {
        VStack(spacing: 4) {
            Text("Auto-start: \(self.store.config.autoStart ? "On" : "Off")")
            Text("Notifications: \(self.store.config.notificationSoundEnabled ? "Sound" : "Silent")")
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
    }
}

#Preview {
    TimerScreen(store: TimerStore())
}
