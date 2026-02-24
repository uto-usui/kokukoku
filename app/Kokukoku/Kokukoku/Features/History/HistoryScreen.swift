import SwiftData
import SwiftUI

private enum HistoryFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case focus = "Focus"
    case breaks = "Breaks"

    var id: String {
        self.rawValue
    }
}

struct HistoryScreen: View {
    @Query(sort: \SessionRecord.endedAt, order: .reverse) private var records: [SessionRecord]
    @State private var filter: HistoryFilter = .all

    var body: some View {
        List {
            if self.filteredRecords.isEmpty {
                ContentUnavailableView("No Sessions Yet", systemImage: "clock.arrow.circlepath")
            } else {
                ForEach(self.filteredRecords, id: \.id) { record in
                    self.historyRow(record)
                }
            }
        }
        .navigationTitle("History")
        .toolbar {
            ToolbarItem(placement: .principal) {
                Picker("Filter", selection: self.$filter) {
                    ForEach(HistoryFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                #if os(iOS)
                .pickerStyle(.segmented)
                #else
                .pickerStyle(.menu)
                #endif
                .frame(minWidth: 180)
            }
        }
    }

    private var filteredRecords: [SessionRecord] {
        switch self.filter {
        case .all:
            self.records
        case .focus:
            self.records.filter { $0.sessionType == .focus }
        case .breaks:
            self.records.filter { $0.sessionType == .shortBreak || $0.sessionType == .longBreak }
        }
    }

    private func historyRow(_ record: SessionRecord) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label(record.sessionType.title, systemImage: record.sessionType.symbolName)
                    .font(.headline)

                Spacer()

                if record.skipped {
                    Text("Skipped")
                        .font(.caption)
                        .foregroundStyle(.orange)
                } else {
                    Text("Completed")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }

            HStack {
                Text("Actual: \(self.durationText(seconds: record.actualDurationSec))")
                Text("Planned: \(self.durationText(seconds: record.plannedDurationSec))")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            Text(record.endedAt, format: Date.FormatStyle(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func durationText(seconds: Int) -> String {
        let minutes = seconds / 60
        let remainder = seconds % 60
        return String(format: "%d:%02d", minutes, remainder)
    }
}
