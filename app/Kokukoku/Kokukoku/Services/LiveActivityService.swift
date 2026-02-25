import Foundation

#if os(iOS) && canImport(ActivityKit)
    import ActivityKit

    @MainActor
    final class LiveActivityService {
        func sync(snapshot: TimerSnapshot) {
            guard #available(iOS 26.2, *),
                  ActivityAuthorizationInfo().areActivitiesEnabled
            else {
                return
            }

            Task {
                if snapshot.timerState == .running, let endDate = snapshot.endDate {
                    let attributes = KokukokuActivityAttributes(activityTitle: "Kokukoku")
                    let state = KokukokuActivityAttributes.ContentState(
                        sessionTitle: snapshot.sessionType.title,
                        timerStateRaw: snapshot.timerState.rawValue,
                        endDate: endDate
                    )
                    let content = ActivityContent(state: state, staleDate: endDate)

                    if let current = Activity<KokukokuActivityAttributes>.activities.first {
                        await current.update(content)
                    } else {
                        _ = try? Activity<KokukokuActivityAttributes>.request(
                            attributes: attributes,
                            content: content
                        )
                    }
                } else {
                    for activity in Activity<KokukokuActivityAttributes>.activities {
                        let finalState = KokukokuActivityAttributes.ContentState(
                            sessionTitle: snapshot.sessionType.title,
                            timerStateRaw: snapshot.timerState.rawValue,
                            endDate: nil
                        )
                        let content = ActivityContent(state: finalState, staleDate: nil)
                        await activity.end(content, dismissalPolicy: .immediate)
                    }
                }
            }
        }
    }
#else
    @MainActor
    final class LiveActivityService {
        func sync(snapshot _: TimerSnapshot) {}
    }
#endif
