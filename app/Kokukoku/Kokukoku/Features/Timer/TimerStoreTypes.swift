import Foundation

struct SessionRecordPayload {
    let sessionType: SessionType
    let startedAt: Date
    let endedAt: Date
    let plannedDurationSec: Int
    let actualDurationSec: Int
    let completed: Bool
    let skipped: Bool
}
