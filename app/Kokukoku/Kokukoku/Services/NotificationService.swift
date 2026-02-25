import Foundation
import UserNotifications

/// Represents the app's notification permission status.
///
/// - `unknown`: Permission has not yet been requested.
/// - `denied`: The user refused notification permission.
/// - `authorized`: Notification permission has been granted.
enum NotificationAuthorizationState: String {
    case unknown
    case denied
    case authorized
}

/// Protocol defining the notification management contract.
protocol NotificationServicing {
    /// Queries the current notification authorization status from the system.
    func refreshAuthorizationState(completion: @escaping (NotificationAuthorizationState) -> Void)

    /// Requests notification permission if not yet determined. Returns the current state if already decided.
    func requestAuthorizationIfNeeded(completion: @escaping (NotificationAuthorizationState) -> Void)

    /// Schedules a local notification for when the current session ends. Cancels any existing pending notification
    /// first.
    func scheduleSessionEndNotification(sessionType: SessionType, fireDate: Date, soundEnabled: Bool)

    /// Cancels the pending session-end notification.
    func cancelSessionEndNotification()
}

final class NotificationService: NotificationServicing {
    private let center: UNUserNotificationCenter

    static let sessionNotificationID = "kokukoku.session.end"

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func refreshAuthorizationState(completion: @escaping (NotificationAuthorizationState) -> Void) {
        self.center.getNotificationSettings { settings in
            let state: NotificationAuthorizationState = switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                .authorized
            case .denied:
                .denied
            case .notDetermined:
                .unknown
            @unknown default:
                .unknown
            }

            completion(state)
        }
    }

    func requestAuthorizationIfNeeded(completion: @escaping (NotificationAuthorizationState) -> Void) {
        self.center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                completion(.authorized)
            case .denied:
                completion(.denied)
            case .notDetermined:
                self.center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
                    completion(granted ? .authorized : .denied)
                }
            @unknown default:
                completion(.unknown)
            }
        }
    }

    func scheduleSessionEndNotification(sessionType: SessionType, fireDate: Date, soundEnabled: Bool) {
        self.cancelSessionEndNotification()

        let content = UNMutableNotificationContent()
        content.title = "\(sessionType.title) completed"
        content.body = self.nextActionText(after: sessionType)
        content.sound = soundEnabled ? .default : nil

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(1, fireDate.timeIntervalSinceNow),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: Self.sessionNotificationID,
            content: content,
            trigger: trigger
        )

        self.center.add(request)
    }

    func cancelSessionEndNotification() {
        self.center.removePendingNotificationRequests(withIdentifiers: [Self.sessionNotificationID])
    }

    private func nextActionText(after sessionType: SessionType) -> String {
        switch sessionType {
        case .focus:
            "Time for a break."
        case .shortBreak, .longBreak:
            "Time to focus."
        }
    }
}
