import Foundation
import SwiftData

@Model
final class UserTimerPreferences {
    var id: UUID
    var focusDurationSec: Int
    var shortBreakDurationSec: Int
    var longBreakDurationSec: Int
    var longBreakFrequency: Int
    var autoStart: Bool
    var notificationSoundEnabled: Bool
    var respectFocusMode: Bool = true
    var ambientNoiseEnabled: Bool = false
    var ambientNoiseVolume: Double = 0.5
    var generativeModeEnabled: Bool = false
    var boundaryStopPolicyRaw: String
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        focusDurationSec: Int,
        shortBreakDurationSec: Int,
        longBreakDurationSec: Int,
        longBreakFrequency: Int,
        autoStart: Bool,
        notificationSoundEnabled: Bool,
        respectFocusMode: Bool = true,
        ambientNoiseEnabled: Bool = false,
        ambientNoiseVolume: Double = 0.5,
        generativeModeEnabled: Bool = false,
        boundaryStopPolicyRaw: String,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.focusDurationSec = focusDurationSec
        self.shortBreakDurationSec = shortBreakDurationSec
        self.longBreakDurationSec = longBreakDurationSec
        self.longBreakFrequency = longBreakFrequency
        self.autoStart = autoStart
        self.notificationSoundEnabled = notificationSoundEnabled
        self.respectFocusMode = respectFocusMode
        self.ambientNoiseEnabled = ambientNoiseEnabled
        self.ambientNoiseVolume = ambientNoiseVolume
        self.generativeModeEnabled = generativeModeEnabled
        self.boundaryStopPolicyRaw = boundaryStopPolicyRaw
        self.updatedAt = updatedAt
    }

    var boundaryStopPolicy: BoundaryStopPolicy {
        get {
            BoundaryStopPolicy(rawValue: self.boundaryStopPolicyRaw) ?? .none
        }
        set {
            self.boundaryStopPolicyRaw = newValue.rawValue
        }
    }
}
