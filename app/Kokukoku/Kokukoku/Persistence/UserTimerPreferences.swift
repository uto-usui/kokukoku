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
