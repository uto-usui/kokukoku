import SwiftUI

struct TimerScreen: View {
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion

    @Bindable var store: TimerStore

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                self.sessionHeader
                if self.useGenerativeMode {
                    self.generativeDisplay
                } else {
                    self.timerDisplay
                    self.progressDisplay
                }
                self.controlButtons
                self.boundaryStopControls
                self.statusFooter
            }
            .padding(24)
            .frame(maxWidth: 680)
            .transaction { transaction in
                if self.accessibilityReduceMotion {
                    transaction.animation = nil
                }
            }
        }
        .navigationTitle("Kokukoku")
    }

    private var sessionHeader: some View {
        HStack(spacing: 6) {
            Image(systemName: self.store.sessionType.symbolName)
                .accessibilityHidden(true)
            Text(self.store.sessionType.title)
        }
        .font(.title3.weight(.medium))
        .foregroundStyle(.secondary)
        .accessibilityElement(children: .combine)
    }

    private var timerDisplay: some View {
        Text(self.store.formattedRemainingTime)
            .font(.system(size: 74, weight: .bold, design: .rounded))
            .monospacedDigit()
            .contentTransition(self.accessibilityReduceMotion ? .identity : .numericText())
            .foregroundStyle(.primary)
            .accessibilityLabel("Remaining time \(self.store.formattedRemainingTime)")
            .accessibilityIdentifier("timer.remaining")
    }

    private var progressDisplay: some View {
        VStack(spacing: 8) {
            ProgressView(value: self.store.progress)
                .progressViewStyle(.linear)
                .tint(.secondary)
                .animation(
                    self.accessibilityReduceMotion ? nil : .easeOut(duration: 0.25),
                    value: self.store.progress
                )
                .accessibilityLabel("Timer progress")
            Text(self.store.focusCycleStatusText)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var controlButtons: some View {
        VStack(spacing: 12) {
            if self.shouldUseColoredPrimaryAction {
                Button(self.store.primaryActionTitle) {
                    self.store.performPrimaryAction()
                }
                .buttonStyle(.borderedProminent)
                .tint(self.primaryActionTintColor)
                .accessibilityIdentifier("timer.primaryAction")
            } else {
                Button(self.store.primaryActionTitle) {
                    self.store.performPrimaryAction()
                }
                .buttonStyle(.bordered)
                .tint(.primary)
                .accessibilityIdentifier("timer.primaryAction")
            }

            HStack(spacing: 10) {
                Button("Reset") {
                    self.store.reset()
                }
                .buttonStyle(.bordered)
                .tint(.primary)
                .disabled(!self.store.canReset)
                .accessibilityIdentifier("timer.reset")

                Button("Skip") {
                    self.store.skip()
                }
                .buttonStyle(.bordered)
                .tint(.primary)
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
        .tint(.secondary)
    }

    private var statusFooter: some View {
        VStack(spacing: 4) {
            Text("Auto-start: \(self.store.config.autoStart ? "On" : "Off")")
            Text("Notifications: \(self.store.effectiveNotificationSoundEnabled ? "Sound" : "Silent")")
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
    }

    private var useGenerativeMode: Bool {
        self.store.config.generativeModeEnabled && !self.accessibilityReduceMotion
    }

    private var generativeDisplay: some View {
        VStack(spacing: 8) {
            GenerativeTimerView(
                elapsed: 0,
                progress: self.store.progress,
                sessionType: self.store.sessionType,
                formattedTime: self.store.formattedRemainingTime
            )
            Text(self.store.focusCycleStatusText)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var shouldUseColoredPrimaryAction: Bool {
        true
    }

    private var primaryActionTintColor: Color {
        switch self.store.timerState {
        case .running:
            .orange
        case .paused, .idle:
            .blue
        }
    }
}

#Preview {
    TimerScreen(store: TimerStore())
}
