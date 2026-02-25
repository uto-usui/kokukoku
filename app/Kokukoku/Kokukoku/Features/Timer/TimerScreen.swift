import SwiftUI

struct TimerScreen: View {
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion

    @Bindable var store: TimerStore
    @State private var secondaryControlsReveal = 0

    var body: some View {
        Group {
            if self.useGenerativeMode {
                self.generativeBody
            } else {
                self.standardBody
            }
        }
        .navigationTitle("Kokukoku")
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
            .transaction { transaction in
                if self.accessibilityReduceMotion {
                    transaction.animation = nil
                }
            }
    }

    // MARK: - Standard Mode

    private var standardBody: some View {
        VStack(spacing: 0) {
            Spacer()

            HStack(spacing: 4) {
                Image(systemName: self.store.sessionType.symbolName)
                    .accessibilityHidden(true)
                Text(self.store.sessionType.title)
            }
            .font(.caption2)
            .foregroundStyle(.tertiary)
            .accessibilityElement(children: .combine)
            .padding(.bottom, 6)

            Text(self.store.formattedRemainingTime)
                .font(.system(size: 96, weight: .thin))
                .monospacedDigit()
                .contentTransition(self.accessibilityReduceMotion ? .identity : .numericText())
                .foregroundStyle(.primary)
                .accessibilityLabel("Remaining time \(self.store.formattedRemainingTime)")
                .accessibilityIdentifier("timer.remaining")

            Text(self.store.focusCycleStatusText)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.top, 4)

            Spacer()

            Button {
                self.store.performPrimaryAction()
            } label: {
                Text(self.store.primaryActionTitle)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
            .background(.ultraThinMaterial, in: Capsule())
            .accessibilityIdentifier("timer.primaryAction")
            .padding(.bottom, 16)

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
            .opacity(self.secondaryControlsReveal > 0 ? 1 : 0)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: 680)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.3)) {
                self.secondaryControlsReveal += 1
            }
        }
        .task(id: self.secondaryControlsReveal) {
            guard self.secondaryControlsReveal > 0 else { return }
            try? await Task.sleep(for: .seconds(3))
            if !Task.isCancelled {
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.secondaryControlsReveal = 0
                }
            }
        }
    }

    // MARK: - Generative Mode

    private var generativeBody: some View {
        ScrollView {
            VStack(spacing: 24) {
                HStack(spacing: 6) {
                    Image(systemName: self.store.sessionType.symbolName)
                        .accessibilityHidden(true)
                    Text(self.store.sessionType.title)
                }
                .font(.title3.weight(.medium))
                .foregroundStyle(.secondary)
                .accessibilityElement(children: .combine)
                .zIndex(1)

                GenerativeTimerView(
                    elapsed: 0,
                    progress: self.store.progress,
                    sessionType: self.store.sessionType,
                    formattedTime: self.store.formattedRemainingTime,
                    cycleStatusText: self.store.focusCycleStatusText
                )
                .padding(.top, -80)

                VStack(spacing: 12) {
                    Button(self.store.primaryActionTitle) {
                        self.store.performPrimaryAction()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(self.generativePrimaryTint)
                    .accessibilityIdentifier("timer.primaryAction")

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
                .zIndex(1)
            }
            .padding(24)
            .frame(maxWidth: 680)
        }
    }

    // MARK: - Helpers

    private var useGenerativeMode: Bool {
        self.store.config.generativeModeEnabled && !self.accessibilityReduceMotion
    }

    private var generativePrimaryTint: Color {
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
