import SwiftUI

struct TimerScreen: View {
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion

    @Bindable var store: TimerStore

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                self.sessionHeader
                    .zIndex(1)
                if self.useGenerativeMode {
                    self.generativeDisplay
                        .padding(.vertical, -20)
                } else {
                    self.timerDisplay
                    self.progressDisplay
                }
                self.controlButtons
                    .zIndex(1)
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
                .controlSize(.large)
                .tint(self.primaryActionTintColor)
                .accessibilityIdentifier("timer.primaryAction")
            } else {
                Button(self.store.primaryActionTitle) {
                    self.store.performPrimaryAction()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .tint(.primary)
                .accessibilityIdentifier("timer.primaryAction")
            }

            HStack(spacing: 10) {
                Button("Reset") {
                    self.store.reset()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(.primary)
                .disabled(!self.store.canReset)
                .accessibilityIdentifier("timer.reset")

                Button("Skip") {
                    self.store.skip()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(.primary)
                .accessibilityIdentifier("timer.skip")
            }
        }
    }

    private var useGenerativeMode: Bool {
        self.store.config.generativeModeEnabled && !self.accessibilityReduceMotion
    }

    private var generativeDisplay: some View {
        GenerativeTimerView(
            elapsed: 0,
            progress: self.store.progress,
            sessionType: self.store.sessionType,
            formattedTime: self.store.formattedRemainingTime,
            cycleStatusText: self.store.focusCycleStatusText
        )
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
