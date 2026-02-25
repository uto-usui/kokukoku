import Foundation

/// A caseless enum serving as a namespace for pure, stateless timer logic.
///
/// All functions are deterministic: same inputs produce the same outputs with no side effects.
/// See docs/adr/004.
enum TimerEngine {
    /// Returns the configured duration in seconds for a given session type.
    ///
    /// - Parameter sessionType: The session type to look up.
    /// - Parameter config: The timer configuration containing duration values.
    /// - Returns: Duration in seconds for the requested session type.
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

    /// Computes remaining seconds based on the current timer state.
    ///
    /// When running, calculates `max(0, ceil(endDate - now))`.
    /// When paused, returns the frozen `pausedRemainingSec`.
    /// When idle, returns the full duration.
    /// Uses `ceil` to avoid displaying 0 while the session is still active.
    ///
    /// - Parameter timerState: The current state of the timer (running, paused, or idle).
    /// - Parameter endDate: The wall-clock time when the session ends, if running.
    /// - Parameter pausedRemainingSec: The frozen remaining seconds captured at pause time.
    /// - Parameter now: The current wall-clock time.
    /// - Parameter fallbackDurationSec: The full session duration used when no other value is available.
    /// - Returns: The number of whole seconds remaining in the session.
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

    /// Returns a 0.0--1.0 progress ratio for the current session.
    ///
    /// Returns 1.0 if `durationSec` is 0 to guard against division by zero.
    ///
    /// - Parameter durationSec: The total session duration in seconds.
    /// - Parameter remainingSec: The number of seconds remaining.
    /// - Returns: A value in the range `0.0...1.0` representing how much of the session has elapsed.
    static func progress(durationSec: Int, remainingSec: Int) -> Double {
        guard durationSec > 0 else {
            return 1.0
        }

        let consumed = max(0, durationSec - remainingSec)
        return min(1.0, max(0.0, Double(consumed) / Double(durationSec)))
    }

    /// Determines the next session type after the current one completes.
    ///
    /// Focus transitions to Short Break, or Long Break when `completedFocusCount`
    /// is divisible by `longBreakFrequency`. Any break transitions back to Focus.
    ///
    /// - Parameter current: The session type that just completed.
    /// - Parameter completedFocusCount: Total number of focus sessions completed so far.
    /// - Parameter config: The timer configuration containing the long break frequency.
    /// - Returns: The session type that should follow.
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

    /// Decides whether to pause auto-advance at a session boundary.
    ///
    /// Skip bypasses the policy and respects only `autoStart`.
    /// When `autoStart` is off, this always stops. See docs/adr/003.
    ///
    /// - Parameter policy: The current boundary-stop policy.
    /// - Parameter nextSessionType: The session type that would start next.
    /// - Parameter dueToSkip: Whether the transition was triggered by a manual skip.
    /// - Parameter autoStart: Whether auto-start is enabled in user settings.
    /// - Returns: A tuple where `shouldStop` indicates whether to pause before the next session,
    ///   and `consumePolicy` indicates whether the policy should be reset after use.
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
