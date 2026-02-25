import Foundation

#if os(iOS)
    import WatchConnectivity
#endif

enum WatchTimerCommand: String {
    case primaryAction
    case reset
    case skip
}

protocol WatchSyncServicing {
    func activate()
    func setCommandHandler(_ handler: (@MainActor (WatchTimerCommand) -> Void)?)
    func sync(snapshot: TimerSnapshot, config: TimerConfig, now: Date)
}

final class WatchConnectivityService: NSObject, WatchSyncServicing {
    private var commandHandler: (@MainActor (WatchTimerCommand) -> Void)?

    func activate() {
        #if os(iOS)
            guard WCSession.isSupported() else {
                return
            }

            let session = WCSession.default
            if session.delegate !== self {
                session.delegate = self
            }

            session.activate()
        #endif
    }

    func setCommandHandler(_ handler: (@MainActor (WatchTimerCommand) -> Void)?) {
        self.commandHandler = handler
    }

    func sync(snapshot: TimerSnapshot, config: TimerConfig, now: Date) {
        #if os(iOS)
            guard WCSession.isSupported() else {
                return
            }

            let context: [String: Any] = [
                Keys.sessionType: snapshot.sessionType.rawValue,
                Keys.timerState: snapshot.timerState.rawValue,
                Keys.boundaryStopPolicy: snapshot.boundaryStopPolicy.rawValue,
                Keys.endDateEpoch: snapshot.endDate?.timeIntervalSince1970 as Any,
                Keys.pausedRemainingSec: snapshot.pausedRemainingSec as Any,
                Keys.completedFocusCount: snapshot.completedFocusCount,
                Keys.longBreakFrequency: config.longBreakFrequency,
                Keys.serverNowEpoch: now.timeIntervalSince1970
            ]

            do {
                try WCSession.default.updateApplicationContext(context)
            } catch {
                // Non-fatal. We'll push the latest snapshot again on next state change.
            }
        #endif
    }
}

#if os(iOS)
extension WatchConnectivityService: WCSessionDelegate {
    func session(_: WCSession, activationDidCompleteWith _: WCSessionActivationState, error _: Error?) {}

    func sessionDidBecomeInactive(_: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    func session(_: WCSession, didReceiveMessage message: [String: Any]) {
        self.handle(message: message)
    }

    func session(_: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        self.handle(message: applicationContext)
    }

    private func handle(message: [String: Any]) {
        guard let rawCommand = message[Keys.command] as? String,
              let command = WatchTimerCommand(rawValue: rawCommand)
        else {
            return
        }

        guard let commandHandler = self.commandHandler else {
            return
        }

        Task { @MainActor in
            commandHandler(command)
        }
    }
}
#endif

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
