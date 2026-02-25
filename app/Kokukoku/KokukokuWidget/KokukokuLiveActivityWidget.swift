import ActivityKit
import SwiftUI
import WidgetKit

struct KokukokuLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: KokukokuActivityAttributes.self) { context in
            VStack(alignment: .leading, spacing: 8) {
                Text(context.state.sessionTitle)
                    .font(.headline)

                self.remainingTimeView(for: context)
                    .font(.title2.monospacedDigit().weight(.semibold))

                Text(self.timerStateText(from: context.state.timerStateRaw))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.state.sessionTitle)
                        .font(.subheadline)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    self.remainingTimeView(for: context)
                        .font(.headline.monospacedDigit())
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(self.timerStateText(from: context.state.timerStateRaw))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } compactLeading: {
                Image(systemName: "timer")
            } compactTrailing: {
                self.remainingTimeView(for: context)
                    .font(.caption2.monospacedDigit())
            } minimal: {
                Image(systemName: "timer")
            }
        }
    }

    private func remainingTimeView(
        for context: ActivityViewContext<KokukokuActivityAttributes>
    ) -> some View {
        Group {
            if let endDate = context.state.endDate,
               context.state.timerStateRaw == "running",
               endDate > Date()
            {
                Text(timerInterval: Date() ... endDate, countsDown: true)
            } else {
                Text("--:--")
            }
        }
    }

    private func timerStateText(from rawValue: String) -> String {
        switch rawValue {
        case "running":
            "Running"
        case "paused":
            "Paused"
        default:
            "Idle"
        }
    }
}
