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

struct BoundaryTransitionContext {
    let endedAt: Date
    let nextType: SessionType
    let nextCompletedFocusCount: Int
    let decision: (shouldStop: Bool, consumePolicy: Bool)
    let dueToSkip: Bool
    let sourceState: TimerState
}
