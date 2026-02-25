import Foundation

/// The lifecycle state of a timer session.
enum TimerState: String, Codable {
    /// Not started, or stopped at a session boundary.
    case idle
    /// Counting down toward ``TimerSnapshot/endDate``.
    case running
    /// Frozen with remaining time saved in ``TimerSnapshot/pausedRemainingSec``.
    case paused
}

/// The three Pomodoro session kinds.
enum SessionType: String, Codable, CaseIterable, Identifiable {
    /// Work session (default 25 minutes).
    case focus
    /// Short rest between focus sessions (default 5 minutes).
    case shortBreak
    /// Extended rest after N focus completions (default 15 minutes).
    case longBreak

    var id: String {
        self.rawValue
    }

    /// Human-readable display label for the session type.
    var title: String {
        switch self {
        case .focus:
            "Focus"
        case .shortBreak:
            "Short Break"
        case .longBreak:
            "Long Break"
        }
    }

    /// SF Symbol name representing the session type.
    var symbolName: String {
        switch self {
        case .focus:
            "timer"
        case .shortBreak:
            "cup.and.saucer"
        case .longBreak:
            "moon.stars"
        }
    }
}

/// Controls whether the timer stops auto-advancing at session boundaries.
///
/// Policies are consumed after firing — once a boundary stop triggers, the policy
/// resets so subsequent transitions are not affected.
enum BoundaryStopPolicy: String, Codable, CaseIterable, Identifiable {
    /// Always auto-advance to the next session without stopping.
    case none
    /// Stop at the very next session end, then reset to ``none``.
    case stopAtNextBoundary
    /// Stop only when a long break would start, then reset to ``none``.
    case stopAtLongBreak

    var id: String {
        self.rawValue
    }

    /// Human-readable display label for the policy.
    var title: String {
        switch self {
        case .none:
            "No Boundary Stop"
        case .stopAtNextBoundary:
            "Stop at Next Boundary"
        case .stopAtLongBreak:
            "Stop at Long Break"
        }
    }
}

/// User-configurable timer settings.
///
/// ``default`` matches the standard Pomodoro technique (25/5/15 minutes,
/// long break every 4 focus completions, auto-start and sound enabled).
struct TimerConfig: Codable, Equatable {
    /// Focus session duration in seconds.
    var focusDurationSec: Int
    /// Short break duration in seconds.
    var shortBreakDurationSec: Int
    /// Long break duration in seconds.
    var longBreakDurationSec: Int
    /// Number of focus completions before a long break triggers.
    var longBreakFrequency: Int
    /// Whether the next session starts automatically after a boundary.
    var autoStart: Bool
    /// Whether notification sounds are enabled on session completion.
    var notificationSoundEnabled: Bool
    /// Whether the timer respects system Focus Mode for muting notification sounds.
    /// When `true`, notification sound is automatically muted while Focus is active.
    var respectFocusMode: Bool
    /// Whether ambient pink noise plays during focus sessions.
    var ambientNoiseEnabled: Bool
    /// Volume level for ambient noise (0.0–1.0).
    var ambientNoiseVolume: Double
    /// Whether generative mode (pulse animation) replaces the standard progress bar.
    var generativeModeEnabled: Bool

    /// Standard Pomodoro defaults: 25/5/15 minutes, frequency 4, auto-start on, sound on, respect Focus on.
    static let `default` = TimerConfig(
        focusDurationSec: 25 * 60,
        shortBreakDurationSec: 5 * 60,
        longBreakDurationSec: 15 * 60,
        longBreakFrequency: 4,
        autoStart: true,
        notificationSoundEnabled: true,
        respectFocusMode: true,
        ambientNoiseEnabled: false,
        ambientNoiseVolume: 0.5,
        generativeModeEnabled: false
    )

    /// Sets the focus duration in minutes, clamped to a minimum of 1 minute.
    mutating func setFocusMinutes(_ minutes: Int) {
        self.focusDurationSec = max(1, minutes) * 60
    }

    /// Sets the short break duration in minutes, clamped to a minimum of 1 minute.
    mutating func setShortBreakMinutes(_ minutes: Int) {
        self.shortBreakDurationSec = max(1, minutes) * 60
    }

    /// Sets the long break duration in minutes, clamped to a minimum of 1 minute.
    mutating func setLongBreakMinutes(_ minutes: Int) {
        self.longBreakDurationSec = max(1, minutes) * 60
    }
}

/// Mutable in-memory state of the current timer session.
///
/// Uses a wall-clock ``endDate`` model: remaining time is computed as
/// `max(0, endDate - now)` rather than counting elapsed seconds. This ensures
/// correct restoration after the app returns from the background.
struct TimerSnapshot: Equatable {
    /// The kind of session currently active (focus, short break, or long break).
    var sessionType: SessionType
    /// The current lifecycle state of the timer.
    var timerState: TimerState
    /// When the current session was started, or `nil` if idle.
    var startedAt: Date?
    /// The wall-clock deadline when the running session ends, or `nil` if not running.
    var endDate: Date?
    /// Remaining seconds frozen at the moment of pause, or `nil` if not paused.
    var pausedRemainingSec: Int?
    /// Number of focus sessions completed in the current cycle. Used to determine long break frequency.
    var completedFocusCount: Int
    /// The active boundary stop policy governing auto-advance behavior.
    var boundaryStopPolicy: BoundaryStopPolicy

    /// A freshly-reset snapshot: idle focus session with no history.
    static let initial = TimerSnapshot(
        sessionType: .focus,
        timerState: .idle,
        startedAt: nil,
        endDate: nil,
        pausedRemainingSec: nil,
        completedFocusCount: 0,
        boundaryStopPolicy: .none
    )
}
