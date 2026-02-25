#if os(iOS) || os(macOS)
    import AVFoundation
    import Foundation

    /// Controls ambient noise playback during focus sessions.
    protocol AmbientNoiseServicing: AnyObject {
        /// Start playing ambient noise at the given volume with a fade-in.
        func start(volume: Double)
        /// Stop playing ambient noise with a fade-out.
        func stop()
        /// Update the playback volume (0.0–1.0).
        func setVolume(_ volume: Double)
    }

    /// Generates pink noise in real time using AVAudioEngine.
    ///
    /// Audio pipeline: `AVAudioSourceNode` (pink noise) → `AVAudioUnitEQ` (lowpass 648 Hz) → mixer → output.
    /// Uses `.playback` + `.mixWithOthers` so other apps (e.g. Spotify) can play simultaneously.
    final class AmbientNoiseService: AmbientNoiseServicing {
        private let engine = AVAudioEngine()
        private var sourceNode: AVAudioSourceNode?
        private var eqNode: AVAudioUnitEQ?
        private var noiseGenerator = PinkNoiseGenerator()
        private var isPlaying = false

        private static let cutoffHz: Float = 648
        private static let resonance: Float = 1.0
        private static let fadeDuration: TimeInterval = 1.0

        func start(volume: Double) {
            guard !self.isPlaying else {
                return
            }

            self.setupAudioSession()
            self.setupEngineIfNeeded()

            self.engine.mainMixerNode.outputVolume = 0
            do {
                try self.engine.start()
            } catch {
                return
            }

            self.isPlaying = true
            self.fadeVolume(to: Float(volume), duration: Self.fadeDuration)
        }

        func stop() {
            guard self.isPlaying else {
                return
            }

            self.fadeVolume(to: 0, duration: Self.fadeDuration) {
                self.engine.stop()
                self.isPlaying = false
            }
        }

        func setVolume(_ volume: Double) {
            guard self.isPlaying else {
                return
            }
            self.engine.mainMixerNode.outputVolume = Float(volume)
        }

        // MARK: - Private

        private func setupAudioSession() {
            #if os(iOS)
                let session = AVAudioSession.sharedInstance()
                try? session.setCategory(.playback, options: .mixWithOthers)
                try? session.setActive(true)
            #endif
        }

        private func setupEngineIfNeeded() {
            guard self.sourceNode == nil else {
                return
            }

            let format = self.engine.mainMixerNode.outputFormat(forBus: 0)
            let generator = self.noiseGenerator

            let source = AVAudioSourceNode(format: format) { _, _, frameCount, audioBufferList -> OSStatus in
                let bufferList = UnsafeMutableAudioBufferListPointer(audioBufferList)
                for buffer in bufferList {
                    guard let data = buffer.mData?.assumingMemoryBound(to: Float.self) else {
                        continue
                    }
                    generator.fill(buffer: data, frameCount: Int(frameCount))
                }
                return noErr
            }
            self.sourceNode = source

            let eq = AVAudioUnitEQ(numberOfBands: 1)
            let band = eq.bands[0]
            band.filterType = .lowPass
            band.frequency = Self.cutoffHz
            band.bandwidth = Self.resonance
            band.bypass = false
            self.eqNode = eq

            self.engine.attach(source)
            self.engine.attach(eq)
            self.engine.connect(source, to: eq, format: format)
            self.engine.connect(eq, to: self.engine.mainMixerNode, format: format)
        }

        private func fadeVolume(to target: Float, duration: TimeInterval, completion: (() -> Void)? = nil) {
            let mixer = self.engine.mainMixerNode
            let steps = 20
            let interval = duration / Double(steps)
            let startVolume = mixer.outputVolume
            let delta = (target - startVolume) / Float(steps)

            DispatchQueue.global(qos: .userInteractive).async {
                for step in 1 ... steps {
                    Thread.sleep(forTimeInterval: interval)
                    DispatchQueue.main.async {
                        mixer.outputVolume = startVolume + delta * Float(step)
                    }
                }
                DispatchQueue.main.async {
                    mixer.outputVolume = target
                    completion?()
                }
            }
        }
    }

    /// Voss-McCartney pink noise generator.
    ///
    /// Produces 1/f spectrum noise by summing white noise contributions across
    /// multiple octave rows. Each sample updates one randomly-selected row,
    /// producing a natural spectral roll-off without explicit filtering.
    final class PinkNoiseGenerator: @unchecked Sendable {
        private static let rowCount = 16
        private var runningSum: Float = 0
        private var rows = [Float](repeating: 0, count: PinkNoiseGenerator.rowCount)

        func fill(buffer: UnsafeMutablePointer<Float>, frameCount: Int) {
            for i in 0 ..< frameCount {
                let white = Float.random(in: -1 ... 1)
                let row = Int.random(in: 0 ..< Self.rowCount)
                self.runningSum -= self.rows[row]
                self.rows[row] = white / Float(Self.rowCount)
                self.runningSum += self.rows[row]
                buffer[i] = (self.runningSum + white / Float(Self.rowCount)) * 0.5
            }
        }
    }
#endif
