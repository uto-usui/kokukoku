import Foundation
import OSLog

#if os(iOS)
    import WatchConnectivity
#endif

private let logger = Logger(subsystem: "com.uto-usui.Kokukoku", category: "WatchSync")

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

            let context = WatchSyncPayload.build(snapshot: snapshot, config: config, now: now)

            do {
                try WCSession.default.updateApplicationContext(context)
            } catch {
                logger.error("updateApplicationContext failed: \(error.localizedDescription)")
                assertionFailure("updateApplicationContext failed: \(error)")
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

enum WatchSyncPayload {
    static func build(snapshot: TimerSnapshot, config: TimerConfig, now: Date) -> [String: Any] {
        let sessionDuration = TimerEngine.duration(for: snapshot.sessionType, config: config)
        var context: [String: Any] = [
            Keys.sessionType: snapshot.sessionType.rawValue,
            Keys.timerState: snapshot.timerState.rawValue,
            Keys.boundaryStopPolicy: snapshot.boundaryStopPolicy.rawValue,
            Keys.completedFocusCount: snapshot.completedFocusCount,
            Keys.longBreakFrequency: config.longBreakFrequency,
            Keys.serverNowEpoch: now.timeIntervalSince1970,
            Keys.sessionDurationSec: sessionDuration
        ]
        if let endDate = snapshot.endDate {
            context[Keys.endDateEpoch] = endDate.timeIntervalSince1970
        }
        if let pausedSec = snapshot.pausedRemainingSec {
            context[Keys.pausedRemainingSec] = pausedSec
        }
        return context
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
    static let sessionDurationSec = "sessionDurationSec"
}
