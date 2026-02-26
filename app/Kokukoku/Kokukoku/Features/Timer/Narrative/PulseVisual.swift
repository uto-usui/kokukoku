import SwiftUI

/// BPM-driven heartbeat particle field.
///
/// Particles pulse with a double-peaked Gaussian envelope (lub-dub pattern)
/// and ripple outward from the center. During break sessions, particle opacity
/// decays gradually over time.
struct PulseVisual: NarrativeVisual {
    // MARK: - Rhythm Parameters

    private static let bpm: Double = 60
    private static let sustain: Double = 2.5
    private static let pulseScale: Double = 0.8
    private static let rippleWidth: Double = 0.12
    private static let rippleSpeed: Double = 1.4

    // MARK: - Particle Parameters

    private static let particleCount = 63
    private static let baseSize: Double = 1.0
    private static let sizeRand: Double = 1.8
    private static let baseAlpha: Double = 0.25
    private static let pulseAlpha: Double = 0.50
    private static let spread: Double = 0.81
    fileprivate static let driftSpeed: Double = 0.31
    fileprivate static let driftRange: Double = 0.07

    // MARK: - Glow Parameters (Dark)

    private static let darkSoftScale: Double = 1.00
    private static let darkAlphaScale: Double = 1.00
    private static let darkInnerR: Double = 0.25
    private static let darkOuterR: Double = 2.5
    private static let darkMidStop: Double = 0.40
    private static let darkMidAlpha: Double = 0.50
    private static let darkCenterGlow: Double = 0.06

    // MARK: - Glow Parameters (Light)

    private static let lightSoftScale: Double = 1.12
    private static let lightAlphaScale: Double = 0.70
    private static let lightInnerR: Double = 0.35
    private static let lightOuterR: Double = 1.7
    private static let lightMidStop: Double = 0.50
    private static let lightMidAlpha: Double = 0.30
    private static let lightCenterGlow: Double = 0.03

    // MARK: - State

    private var particles: [Particle] = []
    private var isInitialized = false

    // MARK: - Draw

    mutating func draw(in context: inout GraphicsContext, input: NarrativeInput) {
        if !self.isInitialized {
            self.initializeParticles(canvasSize: input.canvasSize)
            self.isInitialized = true
        }

        let dt = 1.0 / 60.0
        let beatPeriod = 60.0 / Self.bpm
        let beatPhase = input.elapsed.truncatingRemainder(dividingBy: beatPeriod) / beatPeriod
        let heartbeatIntensity = Self.heartbeatEnvelope(phase: beatPhase)

        let sessionAlpha = Self.sessionAlpha(sessionType: input.sessionType, progress: input.progress)
        let center = CGPoint(x: input.canvasSize.width / 2, y: input.canvasSize.height / 2)
        let maxRadius = min(input.canvasSize.width, input.canvasSize.height) / 2

        let softScale = input.isDarkMode ? Self.darkSoftScale : Self.lightSoftScale
        let alphaScale = input.isDarkMode ? Self.darkAlphaScale : Self.lightAlphaScale
        let innerR = input.isDarkMode ? Self.darkInnerR : Self.lightInnerR
        let outerR = input.isDarkMode ? Self.darkOuterR : Self.lightOuterR
        let midStop = input.isDarkMode ? Self.darkMidStop : Self.lightMidStop
        let midAlpha = input.isDarkMode ? Self.darkMidAlpha : Self.lightMidAlpha
        // Warm tones matching the HTML mockup
        let baseColor = input.isDarkMode
            ? Color(red: 220.0 / 255, green: 218.0 / 255, blue: 214.0 / 255)
            : Color(red: 75.0 / 255, green: 65.0 / 255, blue: 55.0 / 255)

        for i in 0 ..< self.particles.count {
            self.particles[i].updateDrift(dt: dt, maxRadius: maxRadius)

            let worldX = center.x + self.particles[i].baseOffset.x + self.particles[i].driftOffset.x
            let worldY = center.y + self.particles[i].baseOffset.y + self.particles[i].driftOffset.y
            let position = CGPoint(x: worldX, y: worldY)
            let distFromCenter = self.particles[i].distFromCenter

            let ripple = Self.rippleIntensity(
                distance: distFromCenter / maxRadius,
                beatPhase: beatPhase,
                beatPeriod: beatPeriod
            )

            let pulseAmount = heartbeatIntensity * ripple

            // Size: base * scale * softScale * individual oscillation (matches mockup)
            let scale = 1.0 + pulseAmount * Self.pulseScale
            let individualOsc = sin(input.elapsed + self.particles[i].phaseOffset) * 0.05
            let finalRadius = max(1.0, self.particles[i].baseSize * scale * softScale * (1.0 + individualOsc))

            // Alpha: (baseAlpha + pulseAmount * pulseAlpha) * sessionAlpha * alphaScale (matches mockup)
            let particleAlpha = min(1.0, (Self.baseAlpha + pulseAmount * Self.pulseAlpha) * sessionAlpha * alphaScale)

            // Radial gradient from innerR to outerR (solid core inside innerR)
            let innerRadius = finalRadius * innerR
            let outerRadius = finalRadius * outerR
            let rect = CGRect(
                x: position.x - outerRadius,
                y: position.y - outerRadius,
                width: outerRadius * 2,
                height: outerRadius * 2
            )

            let gradient = Gradient(stops: [
                .init(color: baseColor.opacity(particleAlpha), location: 0),
                .init(color: baseColor.opacity(particleAlpha * midAlpha), location: midStop),
                .init(color: baseColor.opacity(0), location: 1.0)
            ])

            context.fill(
                Path(ellipseIn: rect),
                with: .radialGradient(
                    gradient,
                    center: position,
                    startRadius: innerRadius,
                    endRadius: outerRadius
                )
            )
        }

        // Center glow: separate pass, drawn once (matches mockup)
        let centerGlow = input.isDarkMode ? Self.darkCenterGlow : Self.lightCenterGlow
        if heartbeatIntensity > 0.1, centerGlow > 0 {
            let glowR = maxRadius * 0.18 * heartbeatIntensity
            let glowA = heartbeatIntensity * centerGlow * sessionAlpha
            let glowGradient = Gradient(stops: [
                .init(color: baseColor.opacity(glowA), location: 0),
                .init(color: baseColor.opacity(0), location: 1.0)
            ])
            let glowRect = CGRect(
                x: center.x - glowR,
                y: center.y - glowR,
                width: glowR * 2,
                height: glowR * 2
            )
            context.fill(
                Path(ellipseIn: glowRect),
                with: .radialGradient(
                    glowGradient,
                    center: center,
                    startRadius: 0,
                    endRadius: glowR
                )
            )
        }
    }

    // MARK: - Heartbeat Envelope

    /// Double-peaked Gaussian envelope simulating a lub-dub heartbeat pattern.
    ///
    /// - Parameter phase: Normalized beat phase (0.0–1.0).
    /// - Returns: Intensity from 0.0 to 1.0.
    static func heartbeatEnvelope(phase: Double) -> Double {
        let attackWidth = 0.035
        let decayWidth = attackWidth * self.sustain

        // First peak (lub) — sharp attack, sustain-scaled decay
        let peak1Pos = 0.08
        let peak1Attack = exp(-pow(phase - peak1Pos, 2) / (2 * attackWidth * attackWidth))
        let peak1Decay = exp(-pow(phase - peak1Pos, 2) / (2 * decayWidth * decayWidth))
        let peak1 = phase < peak1Pos ? peak1Attack : peak1Decay

        // Second peak (dub) — slightly wider, lower amplitude
        let peak2Pos = peak1Pos + 0.10
        let peak2Width = attackWidth * 1.5
        let peak2DecayWidth = peak2Width * self.sustain
        let peak2Attack = exp(-pow(phase - peak2Pos, 2) / (2 * peak2Width * peak2Width))
        let peak2Decay = exp(-pow(phase - peak2Pos, 2) / (2 * peak2DecayWidth * peak2DecayWidth))
        let peak2 = (phase < peak2Pos ? peak2Attack : peak2Decay) * 0.45

        return min(1.0, peak1 + peak2)
    }

    // MARK: - Ripple

    /// Compute ripple intensity at a given distance from center.
    ///
    /// - Parameters:
    ///   - distance: Normalized distance from center (0.0–1.0+).
    ///   - beatPhase: Normalized beat phase (0.0–1.0).
    ///   - beatPeriod: Duration of one beat in seconds.
    /// - Returns: Intensity from 0.0 to 1.0.
    static func rippleIntensity(distance: Double, beatPhase: Double, beatPeriod _: Double) -> Double {
        let waveFront = beatPhase * self.rippleSpeed
        let diff = abs(distance - waveFront)
        return exp(-pow(diff, 2) / (2 * self.rippleWidth * self.rippleWidth))
    }

    // MARK: - Session Alpha (Break Decay)

    /// Compute opacity multiplier for break sessions.
    ///
    /// During break sessions, opacity gradually decays. During focus sessions, returns 1.0.
    ///
    /// - Parameters:
    ///   - sessionType: The current session type.
    ///   - progress: Session progress from 0.0 to 1.0.
    /// - Returns: Alpha multiplier (0.05–1.0).
    static func sessionAlpha(sessionType: SessionType, progress: Double) -> Double {
        guard sessionType != .focus else {
            return 1.0
        }
        return max(0.05, 1.0 - progress * 0.8)
    }

    // MARK: - Particle Initialization

    private mutating func initializeParticles(canvasSize: CGSize) {
        let maxR = min(canvasSize.width, canvasSize.height) / 2 * Self.spread

        self.particles = (0 ..< Self.particleCount).map { _ in
            let angle = Double.random(in: 0 ..< .pi * 2)
            let radius = sqrt(Double.random(in: 0 ... 1)) * maxR
            let baseX = cos(angle) * radius
            let baseY = sin(angle) * radius
            let size = Self.baseSize + Double.random(in: 0 ... Self.sizeRand)

            return Particle(
                baseOffset: CGPoint(x: baseX, y: baseY),
                distFromCenter: radius,
                driftOffset: .zero,
                driftVelocity: CGPoint(
                    x: (Double.random(in: 0 ... 1) - 0.5) * PulseVisual.driftSpeed,
                    y: (Double.random(in: 0 ... 1) - 0.5) * PulseVisual.driftSpeed
                ),
                baseSize: size,
                phaseOffset: Double.random(in: 0 ..< .pi * 2)
            )
        }
    }
}

// MARK: - Particle

private struct Particle {
    let baseOffset: CGPoint
    let distFromCenter: Double
    var driftOffset: CGPoint
    var driftVelocity: CGPoint
    let baseSize: Double
    let phaseOffset: Double

    mutating func updateDrift(dt: Double, maxRadius: Double) {
        // Brownian motion: random acceleration scaled by dt
        self.driftVelocity.x += CGFloat((Double.random(in: 0 ... 1) - 0.5) * PulseVisual.driftSpeed * dt)
        self.driftVelocity.y += CGFloat((Double.random(in: 0 ... 1) - 0.5) * PulseVisual.driftSpeed * dt)

        // Gentle home return force
        self.driftVelocity.x -= self.driftOffset.x * 0.002
        self.driftVelocity.y -= self.driftOffset.y * 0.002

        // Damping
        self.driftVelocity.x *= 0.98
        self.driftVelocity.y *= 0.98

        // Update drift offset scaled by dt
        self.driftOffset.x += self.driftVelocity.x * dt
        self.driftOffset.y += self.driftVelocity.y * dt

        // Clamp total drift distance
        let maxDrift = maxRadius * PulseVisual.driftRange
        let dist = sqrt(self.driftOffset.x * self.driftOffset.x + self.driftOffset.y * self.driftOffset.y)
        if dist > maxDrift {
            self.driftOffset.x *= maxDrift / dist
            self.driftOffset.y *= maxDrift / dist
        }
    }
}
