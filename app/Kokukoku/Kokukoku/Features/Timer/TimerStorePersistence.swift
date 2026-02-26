import Foundation
import SwiftData

extension TimerStore {
    func loadPreferencesIfNeeded() {
        guard self.preferences == nil, let modelContext = self.modelContext else {
            return
        }

        do {
            var descriptor = FetchDescriptor<UserTimerPreferences>()
            descriptor.fetchLimit = 1

            if let stored = try modelContext.fetch(descriptor).first {
                self.preferences = stored
                self.applyPreferences(stored)
                return
            }

            let defaults = UserTimerPreferences(
                focusDurationSec: TimerConfig.default.focusDurationSec,
                shortBreakDurationSec: TimerConfig.default.shortBreakDurationSec,
                longBreakDurationSec: TimerConfig.default.longBreakDurationSec,
                longBreakFrequency: TimerConfig.default.longBreakFrequency,
                autoStart: TimerConfig.default.autoStart,
                notificationSoundEnabled: TimerConfig.default.notificationSoundEnabled,
                respectFocusMode: TimerConfig.default.respectFocusMode,
                ambientNoiseEnabled: TimerConfig.default.ambientNoiseEnabled,
                ambientNoiseVolume: TimerConfig.default.ambientNoiseVolume,
                narrativeModeEnabled: TimerConfig.default.narrativeModeEnabled,
                boundaryStopPolicyRaw: BoundaryStopPolicy.none.rawValue
            )

            modelContext.insert(defaults)
            try modelContext.save()
            self.preferences = defaults
            self.applyPreferences(defaults)
        } catch {
            self.lastErrorMessage = "Failed to load preferences: \(error.localizedDescription)"
        }
    }

    func applyPreferences(_ preferences: UserTimerPreferences) {
        self.config = TimerConfig(
            focusDurationSec: max(60, preferences.focusDurationSec),
            shortBreakDurationSec: max(60, preferences.shortBreakDurationSec),
            longBreakDurationSec: max(60, preferences.longBreakDurationSec),
            longBreakFrequency: max(1, preferences.longBreakFrequency),
            autoStart: preferences.autoStart,
            notificationSoundEnabled: preferences.notificationSoundEnabled,
            respectFocusMode: preferences.respectFocusMode,
            ambientNoiseEnabled: preferences.ambientNoiseEnabled,
            ambientNoiseVolume: preferences.ambientNoiseVolume,
            narrativeModeEnabled: preferences.narrativeModeEnabled
        )

        self.snapshot.boundaryStopPolicy = preferences.boundaryStopPolicy
    }

    func persistPreferences() {
        guard let modelContext = self.modelContext else {
            return
        }

        if self.preferences == nil {
            self.loadPreferencesIfNeeded()
        }

        guard let preferences = self.preferences else {
            return
        }

        preferences.focusDurationSec = self.config.focusDurationSec
        preferences.shortBreakDurationSec = self.config.shortBreakDurationSec
        preferences.longBreakDurationSec = self.config.longBreakDurationSec
        preferences.longBreakFrequency = self.config.longBreakFrequency
        preferences.autoStart = self.config.autoStart
        preferences.notificationSoundEnabled = self.config.notificationSoundEnabled
        preferences.respectFocusMode = self.config.respectFocusMode
        preferences.ambientNoiseEnabled = self.config.ambientNoiseEnabled
        preferences.ambientNoiseVolume = self.config.ambientNoiseVolume
        preferences.narrativeModeEnabled = self.config.narrativeModeEnabled
        preferences.boundaryStopPolicy = self.snapshot.boundaryStopPolicy
        preferences.updatedAt = Date()

        do {
            try modelContext.save()
        } catch {
            self.lastErrorMessage = "Failed to save preferences: \(error.localizedDescription)"
        }
    }

    func persistSessionRecord(_ payload: SessionRecordPayload) {
        guard let modelContext = self.modelContext else {
            return
        }

        let record = SessionRecord(
            sessionTypeRaw: payload.sessionType.rawValue,
            startedAt: payload.startedAt,
            endedAt: payload.endedAt,
            plannedDurationSec: payload.plannedDurationSec,
            actualDurationSec: payload.actualDurationSec,
            completed: payload.completed,
            skipped: payload.skipped
        )

        modelContext.insert(record)

        do {
            try modelContext.save()
        } catch {
            self.lastErrorMessage = "Failed to save session record: \(error.localizedDescription)"
        }
    }
}
