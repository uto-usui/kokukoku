# Material Surface & Typography Design

**Goal:** Transform the timer screen from "text on a white screen" to "time etched into iPhone glass." Achieve a Leica/Apple-grade solid UI by stripping decoration and fusing with hardware.

## Layer Structure

### Background
- `ZStack` backmost: `.background(.ultraThinMaterial, ignoresSafeAreaEdges: .all)`
- Material provides vibrancy context for hierarchical foreground styles

### Surface Texture (Grain)
- Canvas or CGImage: grayscale noise tiled at 0.03–0.05 opacity
- Converts digital smoothness into physical surface texture
- Implementation: 128x128 `CGImage` generated once, tiled via `.resizable(resizingMode: .tile)`
- Disabled when Increase Contrast accessibility setting is enabled

## Typography

### Main Timer (digits)
- `font: .system(size: 100, weight: .thin)`
- `.monospacedDigit()` — eliminate layout jitter during countdown
- `.foregroundStyle(.primary)` — vibrant via material context
- `.contentTransition(.numericText(countsDown: true))`

### Labels (Focus / Cycle)
- Focus: `.subheadline`, `.foregroundStyle(.secondary)`
- Cycle: `.caption`, `.foregroundStyle(.secondary)`

### Title (Kokukoku)
- `.foregroundStyle(.tertiary)` — recede visually
- Fade to `.opacity(0)` when timer is running

## Button Design
- Shape: `Capsule().fill(.tertiary)` — no stroke, color-only affordance ("surface indentation")
- Label: `.foregroundStyle(.primary)`

## Vibrancy Note
- `.primary.vibrant` is NOT a public SwiftUI API (confirmed via SDK typecheck)
- Vibrancy is automatic when using hierarchical styles (`.primary/.secondary/.tertiary`) over a `.material` background
- Custom colors (e.g., `.foregroundStyle(.blue)`) disable vibrancy

## Accessibility
- **Dynamic Type**: padding-based button sizing, no fixed dimensions
- **Increase Contrast**: grain overlay disabled, material becomes more opaque automatically
- **Reduce Motion**: content transitions set to `.identity`
