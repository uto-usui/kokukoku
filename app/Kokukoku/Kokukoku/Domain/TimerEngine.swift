import Foundation

enum TimerEngine {
    static func duration(for sessionType: SessionType, config: TimerConfig) -> Int {
        switch sessionType {
        case .focus:
            config.focusDurationSec
        case .shortBreak:
            config.shortBreakDurationSec
        case .longBreak:
            config.longBreakDurationSec
        }
    }

    static func remainingSeconds(
        timerState: TimerState,
        endDate: Date?,
        pausedRemainingSec: Int?,
        now: Date,
        fallbackDurationSec: Int
    ) -> Int {
        switch timerState {
        case .running:
            guard let endDate else {
                return fallbackDurationSec
            }
            return max(0, Int(ceil(endDate.timeIntervalSince(now))))
        case .paused:
            return max(0, pausedRemainingSec ?? fallbackDurationSec)
        case .idle:
            return fallbackDurationSec
        }
    }

    static func progress(durationSec: Int, remainingSec: Int) -> Double {
        guard durationSec > 0 else {
            return 1.0
        }

        let consumed = max(0, durationSec - remainingSec)
        return min(1.0, max(0.0, Double(consumed) / Double(durationSec)))
    }

    static func nextSessionType(current: SessionType, completedFocusCount: Int, config: TimerConfig) -> SessionType {
        switch current {
        case .focus:
            if completedFocusCount > 0, completedFocusCount % max(1, config.longBreakFrequency) == 0 {
                return .longBreak
            }
            return .shortBreak
        case .shortBreak, .longBreak:
            return .focus
        }
    }

    static func shouldStopAtBoundary(
        policy: BoundaryStopPolicy,
        nextSessionType: SessionType,
        dueToSkip: Bool,
        autoStart: Bool
    ) -> (shouldStop: Bool, consumePolicy: Bool) {
        if dueToSkip {
            return (!autoStart, false)
        }

        if !autoStart {
            return (true, false)
        }

        switch policy {
        case .none:
            return (false, false)
        case .stopAtNextBoundary:
            return (true, true)
        case .stopAtLongBreak:
            return nextSessionType == .longBreak ? (true, true) : (false, false)
        }
    }
}
