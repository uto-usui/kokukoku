import SwiftUI

struct TimerScreen: View {
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    @Bindable var store: TimerStore

    var body: some View {
        self.standardBody
            .background {
                if self.useNarrativeMode {
                    NarrativeTimerView(
                        elapsed: 0,
                        progress: self.store.progress,
                        sessionType: self.store.sessionType
                    )
                    .ignoresSafeArea()
                }
            }
            .background(.ultraThinMaterial, ignoresSafeAreaEdges: .all)
            .overlay {
                if self.colorSchemeContrast != .increased {
                    GrainOverlay()
                        .opacity(0.04)
                        .allowsHitTesting(false)
                        .ignoresSafeArea()
                }
            }
            .navigationTitle("Kokukoku")
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Kokukoku")
                        .foregroundStyle(.tertiary)
                        .opacity(self.store.timerState == .running ? 0 : 1)
                        .animation(.easeInOut(duration: 0.3), value: self.store.timerState)
                }
            }
        #endif
            .transaction { transaction in
                if self.accessibilityReduceMotion {
                    transaction.animation = nil
                }
            }
    }

    // MARK: - Standard Mode

    private var standardBody: some View {
        VStack(spacing: 0) {
            Spacer()

            HStack(spacing: 4) {
                Image(systemName: self.store.sessionType.symbolName)
                    .accessibilityHidden(true)
                Text(self.store.sessionType.title)
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .accessibilityElement(children: .combine)
            .padding(.bottom, 6)

            Text(self.store.formattedRemainingTime)
                .font(.system(size: 100, weight: .thin))
                .monospacedDigit()
                .contentTransition(.numericText(countsDown: true))
                .foregroundStyle(.primary)
                .accessibilityLabel("Remaining time \(self.store.formattedRemainingTime)")
                .accessibilityIdentifier("timer.remaining")

            Text(self.store.focusCycleStatusText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 4)

            Spacer()

            Button {
                self.store.performPrimaryAction()
            } label: {
                Text(self.store.primaryActionTitle)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
            .background(Capsule().fill(.tertiary))
            .accessibilityIdentifier("timer.primaryAction")
            .padding(.bottom, 16)

            HStack(spacing: 10) {
                Button("Reset") {
                    self.store.reset()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(.primary)
                .disabled(!self.store.canReset)
                .accessibilityIdentifier("timer.reset")

                Button("Skip") {
                    self.store.skip()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(.primary)
                .accessibilityIdentifier("timer.skip")
            }
            .opacity(self.store.timerState == .paused ? 1 : 0)
            .animation(.easeInOut(duration: 0.3), value: self.store.timerState)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: 680)
    }

    // MARK: - Helpers

    private var useNarrativeMode: Bool {
        self.store.config.narrativeModeEnabled && !self.accessibilityReduceMotion
    }
}

// MARK: - Grain Overlay

/// Tiled grayscale noise texture for surface materiality.
///
/// Generates a 128x128 noise `CGImage` once at load time and tiles it
/// across the view. Apply at low opacity (0.03–0.05) over a material
/// background to convert digital smoothness into physical surface texture.
private struct GrainOverlay: View {
    private static let grainImage: CGImage? = {
        let size = 128
        var pixels = [UInt8](repeating: 0, count: size * size * 4)
        for px in 0 ..< size * size {
            let val = UInt8.random(in: 0 ... 255)
            pixels[px * 4] = val
            pixels[px * 4 + 1] = val
            pixels[px * 4 + 2] = val
            pixels[px * 4 + 3] = 255
        }
        guard let provider = CGDataProvider(data: Data(pixels) as CFData) else { return nil }
        return CGImage(
            width: size,
            height: size,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: size * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )
    }()

    var body: some View {
        if let cgImage = Self.grainImage {
            Image(decorative: cgImage, scale: 2)
                .resizable(resizingMode: .tile)
        }
    }
}

#Preview {
    TimerScreen(store: TimerStore())
}
