import SwiftUI
import WidgetKit

private struct KokukokuStatusEntry: TimelineEntry {
    let date: Date
}

private struct KokukokuStatusProvider: TimelineProvider {
    func placeholder(in _: Context) -> KokukokuStatusEntry {
        KokukokuStatusEntry(date: Date())
    }

    func getSnapshot(in _: Context, completion: @escaping (KokukokuStatusEntry) -> Void) {
        completion(KokukokuStatusEntry(date: Date()))
    }

    func getTimeline(in _: Context, completion: @escaping (Timeline<KokukokuStatusEntry>) -> Void) {
        let now = Date()
        let entries = [KokukokuStatusEntry(date: now)]
        completion(Timeline(entries: entries, policy: .after(now.addingTimeInterval(60))))
    }
}

private struct KokukokuStatusEntryView: View {
    let entry: KokukokuStatusEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Kokukoku")
                .font(.headline)
            Text("Focus 25:00")
                .font(.title3.monospacedDigit().weight(.semibold))
            Text(entry.date, style: .time)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding()
    }
}

struct KokukokuStatusWidget: Widget {
    private let kind = "KokukokuStatusWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: self.kind, provider: KokukokuStatusProvider()) { entry in
            KokukokuStatusEntryView(entry: entry)
        }
        .configurationDisplayName("Kokukoku")
        .description("Quick glance at your current session.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
