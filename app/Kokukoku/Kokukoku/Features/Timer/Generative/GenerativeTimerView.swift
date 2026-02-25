import SwiftUI

/// Displays a generative visual animation driven by timer state.
///
/// Uses `TimelineView(.animation)` for frame-rate updates and `Canvas` for drawing.
/// Falls back to standard progress bar when `accessibilityReduceMotion` is enabled.
struct GenerativeTimerView: View {
    @Environment(\.colorScheme) private var colorScheme

    let elapsed: TimeInterval
    let progress: Double
    let sessionType: SessionType
    let formattedTime: String

    @State private var visualState = VisualState()
    @State private var startDate: Date?

    var body: some View {
        TimelineView(.animation) { timeline in
            let currentElapsed = self.computeElapsed(from: timeline.date)

            Canvas { context, size in
                let input = GenerativeInput(
                    elapsed: currentElapsed,
                    progress: self.progress,
                    sessionType: self.sessionType,
                    canvasSize: size,
                    isDarkMode: self.colorScheme == .dark
                )
                self.visualState.visual.draw(in: &context, input: input)
            }
            .overlay(alignment: .bottom) {
                Text(self.formattedTime)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.primary)
                    .padding(.bottom, 16)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityLabel("Timer progress \(Int(self.progress * 100))%")
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
    var visual: any GenerativeVisual = GenerativeVisualFactory.visual()
}
