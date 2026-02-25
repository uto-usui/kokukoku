import Foundation

#if os(iOS) && canImport(ActivityKit)
    import ActivityKit

    struct KokukokuActivityAttributes: ActivityAttributes {
        struct ContentState: Codable, Hashable {
            var sessionTitle: String
            var timerStateRaw: String
            var endDate: Date?
        }

        var activityTitle: String
    }
#endif
