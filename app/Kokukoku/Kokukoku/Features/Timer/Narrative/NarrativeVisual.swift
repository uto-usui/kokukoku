import SwiftUI

/// Input data provided to a narrative visual each frame.
struct NarrativeInput {
    /// Session elapsed time in seconds (drives rhythm phase).
    let elapsed: TimeInterval
    /// Session progress from 0.0 (start) to 1.0 (complete).
    let progress: Double
    /// The current session type (affects visual expression).
    let sessionType: SessionType
    /// The canvas size in points.
    let canvasSize: CGSize
    /// Whether the system is in dark mode.
    let isDarkMode: Bool
}

/// A narrative visual that draws into a SwiftUI `GraphicsContext` each frame.
protocol NarrativeVisual {
    /// Draw the visual for the current frame.
    mutating func draw(in context: inout GraphicsContext, input: NarrativeInput)
}

/// Factory for creating narrative visuals.
enum NarrativeVisualFactory {
    static func visual() -> any NarrativeVisual {
        PulseVisual()
    }
}
