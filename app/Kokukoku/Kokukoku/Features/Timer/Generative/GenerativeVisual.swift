import SwiftUI

/// Input data provided to a generative visual each frame.
struct GenerativeInput {
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

/// A generative visual that draws into a SwiftUI `GraphicsContext` each frame.
protocol GenerativeVisual {
    /// Draw the visual for the current frame.
    mutating func draw(in context: inout GraphicsContext, input: GenerativeInput)
}

/// Factory for creating generative visuals.
enum GenerativeVisualFactory {
    static func visual() -> any GenerativeVisual {
        PulseVisual()
    }
}
