import SwiftUI

/// Displays a narrative visual animation driven by timer state.
///
/// Uses `TimelineView(.animation)` for frame-rate updates and `Canvas` for drawing.
/// Intended to be used as a background layer behind the standard timer UI.
struct NarrativeTimerView: View {
    @Environment(\.colorScheme) private var colorScheme

    let elapsed: TimeInterval
    let progress: Double
    let sessionType: SessionType

    @State private var visualState = VisualState()
    @State private var startDate: Date?

    var body: some View {
        TimelineView(.animation) { timeline in
            let currentElapsed = self.computeElapsed(from: timeline.date)

            Canvas { context, size in
                let input = NarrativeInput(
                    elapsed: currentElapsed,
                    progress: self.progress,
                    sessionType: self.sessionType,
                    canvasSize: size,
                    isDarkMode: self.colorScheme == .dark
                )
                self.visualState.visual.draw(in: &context, input: input)
            }
        }
        .accessibilityHidden(true)
        .allowsHitTesting(false)
        .onAppear {
            self.startDate = Date()
        }
    }

    private func computeElapsed(from date: Date) -> TimeInterval {
        guard let start = self.startDate else {
            return self.elapsed
        }
        return self.elapsed + date.timeIntervalSince(start)
    }
}

/// Reference-type wrapper so that `Canvas` (which uses an `@escaping` closure)
/// can persist mutations to the visual's particle state across frames.
private final class VisualState {
    var visual: any NarrativeVisual = NarrativeVisualFactory.visual()
}
