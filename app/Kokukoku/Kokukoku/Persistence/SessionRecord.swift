import Foundation
import SwiftData

@Model
final class SessionRecord {
    var id: UUID
    var sessionTypeRaw: String
    var startedAt: Date
    var endedAt: Date
    var plannedDurationSec: Int
    var actualDurationSec: Int
    var completed: Bool
    var skipped: Bool

    init(
        id: UUID = UUID(),
        sessionTypeRaw: String,
        startedAt: Date,
        endedAt: Date,
        plannedDurationSec: Int,
        actualDurationSec: Int,
        completed: Bool,
        skipped: Bool
    ) {
        self.id = id
        self.sessionTypeRaw = sessionTypeRaw
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.plannedDurationSec = plannedDurationSec
        self.actualDurationSec = actualDurationSec
        self.completed = completed
        self.skipped = skipped
    }

    var sessionType: SessionType {
        SessionType(rawValue: self.sessionTypeRaw) ?? .focus
    }
}
