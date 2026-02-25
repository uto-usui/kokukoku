import Foundation
import Observation
import WatchConnectivity

@MainActor
@Observable
final class WatchSessionStore: NSObject {
    var sessionTypeTitle: String = "Focus"
    var timerState: WatchTimerState = .idle
    var boundaryStopPolicyTitle: String = "No Boundary Stop"
    var endDate: Date?
    var pausedRemainingSec: Int?
    var completedFocusCount: Int = 0
    var longBreakFrequency: Int = 4
    var now: Date = .init()
    var isReachable: Bool = false
    var lastErrorMessage: String?

    @ObservationIgnored private var ticker: Timer?

    var remainingSeconds: Int {
        switch self.timerState {
        case .running:
            guard let endDate else { return 0 }
            return max(0, Int(ceil(endDate.timeIntervalSince(self.now))))
        case .paused:
            return max(0, self.pausedRemainingSec ?? 0)
        case .idle:
            return max(0, self.pausedRemainingSec ?? 0)
        }
    }

    var formattedRemainingTime: String {
        let total = self.remainingSeconds
        return String(format: "%02d:%02d", total / 60, total % 60)
    }

    var primaryActionTitle: String {
        switch self.timerState {
        case .idle:
            "Start"
        case .running:
            "Pause"
        case .paused:
            "Resume"
        }
    }

    var cycleText: String {
        let frequency = max(1, self.longBreakFrequency)
        return "Cycle: \(self.completedFocusCount % frequency)/\(frequency)"
    }

    func bind() {
        self.startTickerIfNeeded()

        guard WCSession.isSupported() else {
            return
        }

        let session = WCSession.default
        session.delegate = self
        session.activate()
        self.isReachable = session.isReachable

        if !session.receivedApplicationContext.isEmpty {
            self.apply(context: session.receivedApplicationContext)
        }
    }

    deinit {
        self.ticker?.invalidate()
    }

    func sendPrimaryAction() {
        self.send(command: .primaryAction)
    }

    func sendReset() {
        self.send(command: .reset)
    }

    func sendSkip() {
        self.send(command: .skip)
    }

    private func startTickerIfNeeded() {
        guard self.ticker == nil else {
            return
        }

        self.ticker = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else {
                return
            }

            Task { @MainActor in
                self.now = Date()
            }
        }
    }

    private func send(command: WatchTimerCommand) {
        let payload = [Keys.command: command.rawValue]
        let session = WCSession.default

        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil) { [weak self] error in
                Task { @MainActor in
                    self?.lastErrorMessage = error.localizedDescription
                }
            }
            return
        }

        do {
            try session.updateApplicationContext(payload)
        } catch {
            self.lastErrorMessage = error.localizedDescription
        }
    }

    private func apply(context: [String: Any]) {
        if let sessionTypeRaw = context[Keys.sessionType] as? String,
           let sessionType = SessionType(rawValue: sessionTypeRaw)
        {
            self.sessionTypeTitle = sessionType.title
        }

        if let timerStateRaw = context[Keys.timerState] as? String,
           let timerState = WatchTimerState(rawValue: timerStateRaw)
        {
            self.timerState = timerState
        }

        if let boundaryRaw = context[Keys.boundaryStopPolicy] as? String,
           let boundary = WatchBoundaryStopPolicy(rawValue: boundaryRaw)
        {
            self.boundaryStopPolicyTitle = boundary.title
        }

        if let endDateEpoch = context[Keys.endDateEpoch] as? Double {
            self.endDate = Date(timeIntervalSince1970: endDateEpoch)
        } else {
            self.endDate = nil
        }

        self.pausedRemainingSec = context[Keys.pausedRemainingSec] as? Int
        self.completedFocusCount = context[Keys.completedFocusCount] as? Int ?? 0
        self.longBreakFrequency = context[Keys.longBreakFrequency] as? Int ?? 4

        if let serverNowEpoch = context[Keys.serverNowEpoch] as? Double {
            self.now = Date(timeIntervalSince1970: serverNowEpoch)
        }
    }
}

extension WatchSessionStore: WCSessionDelegate {
    nonisolated func session(_: WCSession, activationDidCompleteWith _: WCSessionActivationState, error _: (any Error)?) {}

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.isReachable = session.isReachable
        }
    }

    nonisolated func session(_: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        Task { @MainActor in
            self.apply(context: applicationContext)
        }
    }
}

private enum Keys {
    static let command = "command"
    static let sessionType = "sessionType"
    static let timerState = "timerState"
    static let boundaryStopPolicy = "boundaryStopPolicy"
    static let endDateEpoch = "endDateEpoch"
    static let pausedRemainingSec = "pausedRemainingSec"
    static let completedFocusCount = "completedFocusCount"
    static let longBreakFrequency = "longBreakFrequency"
    static let serverNowEpoch = "serverNowEpoch"
}

enum WatchTimerCommand: String {
    case primaryAction
    case reset
    case skip
}

enum WatchTimerState: String {
    case idle
    case running
    case paused
}

private enum SessionType: String {
    case focus
    case shortBreak
    case longBreak

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
}

private enum WatchBoundaryStopPolicy: String {
    case none
    case stopAtNextBoundary
    case stopAtLongBreak

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
