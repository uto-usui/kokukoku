import SwiftData
import SwiftUI

#if os(macOS)
    struct MenuBarTimerView: View {
        @Environment(\.modelContext) private var modelContext
        @Environment(\.openWindow) private var openWindow

        @Bindable var store: TimerStore

        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label(self.store.sessionType.title, systemImage: self.store.sessionType.symbolName)
                        .font(.headline)
                    Spacer()
                    Text(self.timerStateText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("menubar.stateLabel")
                }

                Text(self.store.formattedRemainingTime)
                    .font(.system(size: 34, weight: .thin))
                    .monospacedDigit()
                    .accessibilityIdentifier("menubar.remaining")

                ProgressView(value: self.store.progress)
                    .progressViewStyle(.linear)
                    .tint(.secondary)

                HStack(spacing: 8) {
                    Button {
                        self.store.performPrimaryAction()
                    } label: {
                        Text(self.store.primaryActionTitle)
                            .font(.body.weight(.medium))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                    .background(Capsule().fill(.tertiary))
                    .accessibilityIdentifier("menubar.primaryAction")

                    Button("Skip") {
                        self.store.skip()
                    }
                    .buttonStyle(.bordered)
                    .tint(.primary)
                    .controlSize(.small)
                    .accessibilityIdentifier("menubar.skip")

                    Button("Reset") {
                        self.store.reset()
                    }
                    .buttonStyle(.bordered)
                    .tint(.primary)
                    .controlSize(.small)
                    .disabled(!self.store.canReset)
                    .accessibilityIdentifier("menubar.reset")
                }

                Divider()

                Button("Open Kokukoku") {
                    self.openWindow(id: "main")
                }
                .buttonStyle(.bordered)
                .tint(.primary)
            }
            .padding(12)
            .frame(width: 280)
            .task {
                self.store.bind(modelContext: self.modelContext)
            }
        }

        private var timerStateText: String {
            switch self.store.timerState {
            case .idle:
                "Idle"
            case .running:
                "Running"
            case .paused:
                "Paused"
            }
        }
    }

    #Preview {
        MenuBarTimerView(store: TimerStore())
            .modelContainer(for: [SessionRecord.self, UserTimerPreferences.self], inMemory: true)
    }
#endif
