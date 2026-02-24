import Foundation

enum TimerState: String, Codable {
    case idle
    case running
    case paused
}

enum SessionType: String, Codable, CaseIterable, Identifiable {
    case focus
    case shortBreak
    case longBreak

    var id: String {
        self.rawValue
    }

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

enum BoundaryStopPolicy: String, Codable, CaseIterable, Identifiable {
    case none
    case stopAtNextBoundary
    case stopAtLongBreak

    var id: String {
        self.rawValue
    }

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

struct TimerConfig: Codable, Equatable {
    var focusDurationSec: Int
    var shortBreakDurationSec: Int
    var longBreakDurationSec: Int
    var longBreakFrequency: Int
    var autoStart: Bool
    var notificationSoundEnabled: Bool

    static let `default` = TimerConfig(
        focusDurationSec: 25 * 60,
        shortBreakDurationSec: 5 * 60,
        longBreakDurationSec: 15 * 60,
        longBreakFrequency: 4,
        autoStart: true,
        notificationSoundEnabled: true
    )

    mutating func setFocusMinutes(_ minutes: Int) {
        self.focusDurationSec = max(1, minutes) * 60
    }

    mutating func setShortBreakMinutes(_ minutes: Int) {
        self.shortBreakDurationSec = max(1, minutes) * 60
    }

    mutating func setLongBreakMinutes(_ minutes: Int) {
        self.longBreakDurationSec = max(1, minutes) * 60
    }
}

struct TimerSnapshot: Equatable {
    var sessionType: SessionType
    var timerState: TimerState
    var startedAt: Date?
    var endDate: Date?
    var pausedRemainingSec: Int?
    var completedFocusCount: Int
    var boundaryStopPolicy: BoundaryStopPolicy

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
