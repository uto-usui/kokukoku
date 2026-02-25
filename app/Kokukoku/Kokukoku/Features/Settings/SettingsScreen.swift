import SwiftUI

struct SettingsScreen: View {
    @Bindable var store: TimerStore

    var body: some View {
        Form {
            self.durationsSection
            self.behaviorSection
            self.focusModeSection
            self.notificationsSection

            if let lastErrorMessage = self.store.lastErrorMessage {
                Section("Diagnostics") {
                    Text(lastErrorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Settings")
    }

    private var durationsSection: some View {
        Section("Durations") {
            Stepper(value: self.focusMinutesBinding, in: 1 ... 180) {
                Text("Focus: \(self.store.config.focusDurationSec / 60) min")
            }

            Stepper(value: self.shortBreakMinutesBinding, in: 1 ... 60) {
                Text("Short Break: \(self.store.config.shortBreakDurationSec / 60) min")
            }

            Stepper(value: self.longBreakMinutesBinding, in: 1 ... 120) {
                Text("Long Break: \(self.store.config.longBreakDurationSec / 60) min")
            }

            Stepper(value: self.longBreakFrequencyBinding, in: 1 ... 10) {
                Text("Long Break every \(self.store.config.longBreakFrequency) focus sessions")
            }
        }
    }

    private var behaviorSection: some View {
        Section("Behavior") {
            Toggle(
                "Auto-start next session",
                isOn: Binding(
                    get: { self.store.config.autoStart },
                    set: { self.store.updateAutoStart($0) }
                )
            )

            Picker(
                "Boundary stop policy",
                selection: Binding(
                    get: { self.store.boundaryStopPolicy },
                    set: { self.store.setBoundaryStopPolicy($0) }
                )
            ) {
                ForEach(BoundaryStopPolicy.allCases) { policy in
                    Text(policy.title).tag(policy)
                }
            }
        }
    }

    private var focusModeSection: some View {
        Section("System Focus") {
            HStack {
                Text("Status")
                Spacer()
                Text(self.focusStatusLabel)
                    .foregroundStyle(.secondary)
            }

            if self.store.focusModeStatus.authorizationState == .unknown {
                Button("Allow Focus Access") {
                    self.store.requestFocusModeAuthorization()
                }
            }

            Text("When Focus is active, notification sound is muted.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var notificationsSection: some View {
        Section("Notifications") {
            Toggle(
                "Sound",
                isOn: Binding(
                    get: { self.store.config.notificationSoundEnabled },
                    set: { self.store.updateNotificationSoundEnabled($0) }
                )
            )

            Text("Permission: \(self.store.notificationAuthorizationState.rawValue)")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Text("Effective sound: \(self.store.effectiveNotificationSoundEnabled ? "On" : "Off")")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var focusMinutesBinding: Binding<Int> {
        Binding(
            get: { self.store.config.focusDurationSec / 60 },
            set: { self.store.updateFocusMinutes($0) }
        )
    }

    private var shortBreakMinutesBinding: Binding<Int> {
        Binding(
            get: { self.store.config.shortBreakDurationSec / 60 },
            set: { self.store.updateShortBreakMinutes($0) }
        )
    }

    private var longBreakMinutesBinding: Binding<Int> {
        Binding(
            get: { self.store.config.longBreakDurationSec / 60 },
            set: { self.store.updateLongBreakMinutes($0) }
        )
    }

    private var longBreakFrequencyBinding: Binding<Int> {
        Binding(
            get: { self.store.config.longBreakFrequency },
            set: { self.store.updateLongBreakFrequency($0) }
        )
    }

    private var focusStatusLabel: String {
        switch self.store.focusModeStatus.authorizationState {
        case .unavailable:
            "Unavailable"
        case .unknown:
            "Not Granted"
        case .restricted:
            "Restricted"
        case .denied:
            "Denied"
        case .authorized:
            self.store.focusModeStatus.isFocused ? "Active" : "Inactive"
        }
    }
}
