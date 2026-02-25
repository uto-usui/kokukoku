import Foundation

#if canImport(Intents)
    import Intents
#endif

/// Represents the app's Focus mode (Do Not Disturb) access level.
///
/// - `unavailable`: The platform does not support the Focus status API.
/// - `unknown`: Authorization has not yet been requested.
/// - `restricted`: Access is restricted by system policy.
/// - `denied`: The user denied Focus status access.
/// - `authorized`: Focus status access has been granted.
enum FocusModeAuthorizationState: String {
    case unavailable
    case unknown
    case restricted
    case denied
    case authorized
}

/// Combines authorization state with whether the user's device is currently in a Focus mode.
struct FocusModeStatus: Equatable {
    var authorizationState: FocusModeAuthorizationState
    var isFocused: Bool

    static let unavailable = FocusModeStatus(authorizationState: .unavailable, isFocused: false)
    static let unknown = FocusModeStatus(authorizationState: .unknown, isFocused: false)
}

/// Protocol defining the Focus mode integration contract.
protocol FocusModeServicing {
    /// Queries the current Focus mode authorization and active status.
    func refreshStatus(completion: @escaping (FocusModeStatus) -> Void)

    /// Requests Focus status access if not yet determined. Uses `INFocusStatusCenter` on supported platforms.
    func requestAuthorizationIfNeeded(completion: @escaping (FocusModeStatus) -> Void)
}

final class FocusModeService: FocusModeServicing {
    func refreshStatus(completion: @escaping (FocusModeStatus) -> Void) {
        completion(self.currentStatus())
    }

    func requestAuthorizationIfNeeded(completion: @escaping (FocusModeStatus) -> Void) {
        #if canImport(Intents)
            if #available(iOS 15.0, macOS 12.0, watchOS 8.0, *) {
                let center = INFocusStatusCenter.default
                let authorization = center.authorizationStatus

                if authorization == .notDetermined {
                    center.requestAuthorization { _ in
                        completion(self.currentStatus())
                    }
                    return
                }

                completion(self.currentStatus())
                return
            }
        #endif

        completion(.unavailable)
    }

    private func currentStatus() -> FocusModeStatus {
        #if canImport(Intents)
            if #available(iOS 15.0, macOS 12.0, watchOS 8.0, *) {
                let center = INFocusStatusCenter.default
                return FocusModeStatus(
                    authorizationState: Self.mapAuthorization(center.authorizationStatus),
                    isFocused: center.focusStatus.isFocused ?? false
                )
            }
        #endif

        return .unavailable
    }

    #if canImport(Intents)
        private static func mapAuthorization(_ value: INFocusStatusAuthorizationStatus) -> FocusModeAuthorizationState {
            switch value {
            case .notDetermined:
                .unknown
            case .restricted:
                .restricted
            case .denied:
                .denied
            case .authorized:
                .authorized
            @unknown default:
                .unknown
            }
        }
    #endif
}
