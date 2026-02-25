import Foundation
@testable import Kokukoku
import SwiftData
import SwiftUI
import Testing

@MainActor
private final class NotificationServiceSpy: NotificationServicing {
    var requestedAuthorizationState: NotificationAuthorizationState
    var refreshedAuthorizationState: NotificationAuthorizationState
    var requestAuthorizationCallCount = 0
    var refreshAuthorizationCallCount = 0
    var scheduleCallCount = 0
    var cancelCallCount = 0
    var lastScheduledSessionType: SessionType?
    var lastScheduledFireDate: Date?
    var lastScheduledSoundEnabled: Bool?

    init(
        requestedAuthorizationState: NotificationAuthorizationState = .authorized,
        refreshedAuthorizationState: NotificationAuthorizationState = .authorized
    ) {
        self.requestedAuthorizationState = requestedAuthorizationState
        self.refreshedAuthorizationState = refreshedAuthorizationState
    }

    func refreshAuthorizationState(completion: @escaping (NotificationAuthorizationState) -> Void) {
        self.refreshAuthorizationCallCount += 1
        completion(self.refreshedAuthorizationState)
    }

    func requestAuthorizationIfNeeded(completion: @escaping (NotificationAuthorizationState) -> Void) {
        self.requestAuthorizationCallCount += 1
        completion(self.requestedAuthorizationState)
    }

    func scheduleSessionEndNotification(sessionType: SessionType, fireDate: Date, soundEnabled: Bool) {
        self.scheduleCallCount += 1
        self.lastScheduledSessionType = sessionType
        self.lastScheduledFireDate = fireDate
        self.lastScheduledSoundEnabled = soundEnabled
    }

    func cancelSessionEndNotification() {
        self.cancelCallCount += 1
    }
}

@MainActor
private final class FocusModeServiceSpy: FocusModeServicing {
    var refreshedStatus = FocusModeStatus(authorizationState: .unknown, isFocused: false)
    var requestedStatus = FocusModeStatus(authorizationState: .unknown, isFocused: false)
    var refreshStatusCallCount = 0
    var requestAuthorizationCallCount = 0

    func refreshStatus(completion: @escaping (FocusModeStatus) -> Void) {
        self.refreshStatusCallCount += 1
        completion(self.refreshedStatus)
    }

    func requestAuthorizationIfNeeded(completion: @escaping (FocusModeStatus) -> Void) {
        self.requestAuthorizationCallCount += 1
        completion(self.requestedStatus)
    }
}

struct TimerEngineTests {
    private let config = TimerConfig.default

    @Test func nextSessionType_usesShortBreakBeforeLongBreakThreshold() {
        let next = TimerEngine.nextSessionType(current: .focus, completedFocusCount: 1, config: self.config)
        #expect(next == .shortBreak)
    }

    @Test func nextSessionType_usesLongBreakAtThreshold() {
        let next = TimerEngine.nextSessionType(current: .focus, completedFocusCount: 4, config: self.config)
        #expect(next == .longBreak)
    }

    @Test func remainingSeconds_usesEndDateWhenRunning() {
        let now = Date(timeIntervalSince1970: 1000)
        let endDate = now.addingTimeInterval(90)

        let remaining = TimerEngine.remainingSeconds(
            timerState: .running,
            endDate: endDate,
            pausedRemainingSec: nil,
            now: now,
            fallbackDurationSec: 10
        )

        #expect(remaining == 90)
    }

    @Test func remainingSeconds_usesPausedValueWhenPaused() {
        let remaining = TimerEngine.remainingSeconds(
            timerState: .paused,
            endDate: nil,
            pausedRemainingSec: 123,
            now: Date(),
            fallbackDurationSec: 10
        )

        #expect(remaining == 123)
    }

    @Test func stopPolicy_stopAtNextBoundary_consumesPolicy() {
        let decision = TimerEngine.shouldStopAtBoundary(
            policy: .stopAtNextBoundary,
            nextSessionType: .shortBreak,
            dueToSkip: false,
            autoStart: true
        )

        #expect(decision.shouldStop)
        #expect(decision.consumePolicy)
    }

    @Test func stopPolicy_stopAtLongBreak_onlyStopsAtLongBreak() {
        let shortBreakDecision = TimerEngine.shouldStopAtBoundary(
            policy: .stopAtLongBreak,
            nextSessionType: .shortBreak,
            dueToSkip: false,
            autoStart: true
        )

        let longBreakDecision = TimerEngine.shouldStopAtBoundary(
            policy: .stopAtLongBreak,
            nextSessionType: .longBreak,
            dueToSkip: false,
            autoStart: true
        )

        #expect(!shortBreakDecision.shouldStop)
        #expect(longBreakDecision.shouldStop)
        #expect(longBreakDecision.consumePolicy)
    }

    @Test func stopPolicy_autoStartOff_alwaysStops() {
        let decision = TimerEngine.shouldStopAtBoundary(
            policy: .none,
            nextSessionType: .shortBreak,
            dueToSkip: false,
            autoStart: false
        )

        #expect(decision.shouldStop)
        #expect(!decision.consumePolicy)
    }
}

@MainActor
struct TimerStoreTests {
    @Test func startPauseResumeReset_primaryActionsTransitionCorrectly() async {
        let notificationSpy = NotificationServiceSpy()
        let store = TimerStore(notificationService: notificationSpy)

        store.start()
        await self.drainMainActorTaskQueue()
        #expect(store.timerState == .running)

        store.pause()
        #expect(store.timerState == .paused)

        store.resume()
        await self.drainMainActorTaskQueue()
        #expect(store.timerState == .running)

        store.reset()
        #expect(store.timerState == .idle)
        #expect(store.sessionType == .focus)
    }

    @Test func stopAtNextBoundary_policyStopsAndConsumesPolicy() {
        let store = TimerStore()
        let now = Date()
        store.now = now
        store.config = TimerConfig.default
        store.snapshot = TimerSnapshot(
            sessionType: .focus,
            timerState: .running,
            startedAt: now.addingTimeInterval(-1500),
            endDate: now.addingTimeInterval(-1),
            pausedRemainingSec: nil,
            completedFocusCount: 0,
            boundaryStopPolicy: .stopAtNextBoundary
        )

        store.handleScenePhaseChange(.active)

        #expect(store.sessionType == .shortBreak)
        #expect(store.timerState == .idle)
        #expect(store.boundaryStopPolicy == .none)
    }

    @Test func restoreFromElapsedRunningSession_transitionsToNextSession() {
        let store = TimerStore()
        let now = Date()
        store.now = now

        store.config = TimerConfig.default
        store.snapshot = TimerSnapshot(
            sessionType: .focus,
            timerState: .running,
            startedAt: now.addingTimeInterval(-1500),
            endDate: now.addingTimeInterval(-5),
            pausedRemainingSec: nil,
            completedFocusCount: 0,
            boundaryStopPolicy: .none
        )

        store.handleScenePhaseChange(.active)

        #expect(store.sessionType == .shortBreak)
        #expect(store.timerState == .running)
        #expect(store.completedFocusCount == 1)
    }

    @Test func restoreWithAutoStartOff_stopsAtBoundary() {
        let store = TimerStore()
        let now = Date()
        store.now = now
        var config = TimerConfig.default
        config.autoStart = false
        store.config = config

        store.snapshot = TimerSnapshot(
            sessionType: .focus,
            timerState: .running,
            startedAt: now.addingTimeInterval(-1500),
            endDate: now.addingTimeInterval(-1),
            pausedRemainingSec: nil,
            completedFocusCount: 0,
            boundaryStopPolicy: .none
        )

        store.handleScenePhaseChange(.active)

        #expect(store.sessionType == .shortBreak)
        #expect(store.timerState == .idle)
    }

    @Test func stopAtLongBreak_policyStopsAndConsumesPolicy() {
        let store = TimerStore()
        let now = Date()
        store.now = now
        store.config = TimerConfig.default
        store.snapshot = TimerSnapshot(
            sessionType: .focus,
            timerState: .running,
            startedAt: now.addingTimeInterval(-1500),
            endDate: now.addingTimeInterval(-1),
            pausedRemainingSec: nil,
            completedFocusCount: 3,
            boundaryStopPolicy: .stopAtLongBreak
        )

        store.handleScenePhaseChange(.active)

        #expect(store.sessionType == .longBreak)
        #expect(store.timerState == .idle)
        #expect(store.boundaryStopPolicy == .none)
    }

    @Test func remainingTime_recomputesWhenNowChanges() {
        let store = TimerStore()
        let base = Date(timeIntervalSince1970: 10000)
        store.now = base
        store.config = TimerConfig.default
        store.snapshot = TimerSnapshot(
            sessionType: .focus,
            timerState: .running,
            startedAt: base,
            endDate: base.addingTimeInterval(120),
            pausedRemainingSec: nil,
            completedFocusCount: 0,
            boundaryStopPolicy: .none
        )

        #expect(store.formattedRemainingTime == "02:00")

        store.now = base.addingTimeInterval(61)
        #expect(store.formattedRemainingTime == "00:59")
    }

    @Test func skipOnFocus_advancesCycleCount() {
        let store = TimerStore()
        let now = Date()
        store.now = now
        store.config = TimerConfig.default
        store.snapshot = TimerSnapshot(
            sessionType: .focus,
            timerState: .running,
            startedAt: now.addingTimeInterval(-300),
            endDate: now.addingTimeInterval(600),
            pausedRemainingSec: nil,
            completedFocusCount: 0,
            boundaryStopPolicy: .none
        )

        store.skip()

        #expect(store.completedFocusCount == 1)
        #expect(store.sessionType == .shortBreak)
    }

    @Test func reset_resetsCycleToZeroAndFocus() {
        let store = TimerStore()
        let now = Date()
        store.now = now
        store.config = TimerConfig.default
        store.snapshot = TimerSnapshot(
            sessionType: .longBreak,
            timerState: .paused,
            startedAt: now.addingTimeInterval(-500),
            endDate: nil,
            pausedRemainingSec: 100,
            completedFocusCount: 3,
            boundaryStopPolicy: .stopAtLongBreak
        )

        store.reset()

        #expect(store.completedFocusCount == 0)
        #expect(store.sessionType == .focus)
        #expect(store.timerState == .idle)
    }

    @Test func skipWhilePaused_keepsPausedForNextSession() {
        let store = TimerStore()
        let now = Date()
        store.now = now
        store.config = TimerConfig.default
        store.snapshot = TimerSnapshot(
            sessionType: .focus,
            timerState: .paused,
            startedAt: now.addingTimeInterval(-500),
            endDate: nil,
            pausedRemainingSec: 30,
            completedFocusCount: 0,
            boundaryStopPolicy: .none
        )

        store.skip()

        #expect(store.completedFocusCount == 1)
        #expect(store.sessionType == .shortBreak)
        #expect(store.timerState == .paused)
        #expect(store.remainingSeconds == TimerConfig.default.shortBreakDurationSec)
    }

    @Test func startWithDeniedNotificationPermission_doesNotScheduleNotification() async {
        let notificationSpy = NotificationServiceSpy(requestedAuthorizationState: .denied)
        let store = TimerStore(notificationService: notificationSpy)

        store.start()
        await self.drainMainActorTaskQueue()

        #expect(store.notificationAuthorizationState == .denied)
        #expect(notificationSpy.scheduleCallCount == 0)
    }

    @Test func pauseResetSkip_cancelPendingNotifications() async {
        let notificationSpy = NotificationServiceSpy()
        let store = TimerStore(notificationService: notificationSpy)

        store.start()
        await self.drainMainActorTaskQueue()
        #expect(notificationSpy.scheduleCallCount == 1)

        store.pause()
        let cancelAfterPause = notificationSpy.cancelCallCount
        #expect(cancelAfterPause > 0)

        store.resume()
        await self.drainMainActorTaskQueue()
        store.reset()
        let cancelAfterReset = notificationSpy.cancelCallCount
        #expect(cancelAfterReset > cancelAfterPause)

        store.start()
        await self.drainMainActorTaskQueue()
        store.skip()
        let cancelAfterSkip = notificationSpy.cancelCallCount
        #expect(cancelAfterSkip > cancelAfterReset)
    }

    @Test func updateNotificationSoundEnabled_reschedulesWithNewSetting() async {
        let notificationSpy = NotificationServiceSpy()
        let store = TimerStore(notificationService: notificationSpy)

        store.start()
        await self.drainMainActorTaskQueue()
        #expect(notificationSpy.lastScheduledSoundEnabled == true)

        store.updateNotificationSoundEnabled(false)
        await self.drainMainActorTaskQueue()
        #expect(notificationSpy.lastScheduledSoundEnabled == false)
        #expect(notificationSpy.scheduleCallCount == 2)
    }

    @Test func respectFocusModeOn_focusActive_mutesSound() {
        let store = TimerStore()
        store.config.notificationSoundEnabled = true
        store.config.respectFocusMode = true
        store.focusModeStatus = FocusModeStatus(authorizationState: .authorized, isFocused: true)

        #expect(store.effectiveNotificationSoundEnabled == false)
    }

    @Test func respectFocusModeOff_focusActive_keepsSound() {
        let store = TimerStore()
        store.config.notificationSoundEnabled = true
        store.config.respectFocusMode = false
        store.focusModeStatus = FocusModeStatus(authorizationState: .authorized, isFocused: true)

        #expect(store.effectiveNotificationSoundEnabled == true)
    }

    @Test func respectFocusModeOn_focusInactive_keepsSound() {
        let store = TimerStore()
        store.config.notificationSoundEnabled = true
        store.config.respectFocusMode = true
        store.focusModeStatus = FocusModeStatus(authorizationState: .authorized, isFocused: false)

        #expect(store.effectiveNotificationSoundEnabled == true)
    }

    @Test func respectFocusModeOff_soundDisabled_staysMuted() {
        let store = TimerStore()
        store.config.notificationSoundEnabled = false
        store.config.respectFocusMode = false
        store.focusModeStatus = FocusModeStatus(authorizationState: .authorized, isFocused: false)

        #expect(store.effectiveNotificationSoundEnabled == false)
    }

    @Test func focusModeActive_mutesScheduledNotificationSound() async {
        let notificationSpy = NotificationServiceSpy()
        let focusSpy = FocusModeServiceSpy()
        focusSpy.refreshedStatus = FocusModeStatus(authorizationState: .authorized, isFocused: true)
        let store = TimerStore(notificationService: notificationSpy, focusModeService: focusSpy)

        store.handleScenePhaseChange(.active)
        await self.drainMainActorTaskQueue()
        store.start()
        await self.drainMainActorTaskQueue()

        #expect(store.focusModeStatus.isFocused)
        #expect(notificationSpy.lastScheduledSoundEnabled == false)
    }

    @Test func completedSession_persistsSessionRecord() throws {
        let notificationSpy = NotificationServiceSpy(requestedAuthorizationState: .denied)
        let store = TimerStore(notificationService: notificationSpy)
        let modelContext = try Self.makeInMemoryModelContext()
        store.bind(modelContext: modelContext)

        let now = Date()
        store.now = now
        store.snapshot = TimerSnapshot(
            sessionType: .focus,
            timerState: .running,
            startedAt: now.addingTimeInterval(-1500),
            endDate: now.addingTimeInterval(-1),
            pausedRemainingSec: nil,
            completedFocusCount: 0,
            boundaryStopPolicy: .none
        )

        store.handleScenePhaseChange(.active)

        let records = try modelContext.fetch(FetchDescriptor<SessionRecord>())
        #expect(records.count == 1)
        #expect(records.first?.completed == true)
        #expect(records.first?.skipped == false)
    }

    @Test func skipSession_persistsSkippedRecord() throws {
        let notificationSpy = NotificationServiceSpy(requestedAuthorizationState: .denied)
        let store = TimerStore(notificationService: notificationSpy)
        let modelContext = try Self.makeInMemoryModelContext()
        store.bind(modelContext: modelContext)

        let now = Date()
        store.now = now
        store.snapshot = TimerSnapshot(
            sessionType: .focus,
            timerState: .running,
            startedAt: now.addingTimeInterval(-400),
            endDate: now.addingTimeInterval(600),
            pausedRemainingSec: nil,
            completedFocusCount: 0,
            boundaryStopPolicy: .none
        )

        store.skip()

        let records = try modelContext.fetch(FetchDescriptor<SessionRecord>())
        #expect(records.count == 1)
        #expect(records.first?.completed == false)
        #expect(records.first?.skipped == true)
    }

    private static func makeInMemoryModelContext() throws -> ModelContext {
        let schema = Schema([
            SessionRecord.self,
            UserTimerPreferences.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        return ModelContext(container)
    }

    private func drainMainActorTaskQueue() async {
        await Task.yield()
        await Task.yield()
    }
}

#if os(iOS) || os(macOS)
    @MainActor
    private final class AmbientNoiseServiceSpy: AmbientNoiseServicing {
        var startCallCount = 0
        var stopCallCount = 0
        var lastStartVolume: Double?
        var lastSetVolume: Double?

        func start(volume: Double) {
            self.startCallCount += 1
            self.lastStartVolume = volume
        }

        func stop() {
            self.stopCallCount += 1
        }

        func setVolume(_ volume: Double) {
            self.lastSetVolume = volume
        }
    }

    @MainActor
    @Suite("AmbientNoise")
    struct AmbientNoiseTests {
        private func makeStore() -> (TimerStore, AmbientNoiseServiceSpy) {
            let noiseSpy = AmbientNoiseServiceSpy()
            let store = TimerStore(
                notificationService: NotificationServiceSpy(requestedAuthorizationState: .denied),
                focusModeService: FocusModeServiceSpy(),
                ambientNoiseService: noiseSpy
            )
            store.config.ambientNoiseEnabled = true
            store.config.ambientNoiseVolume = 0.5
            return (store, noiseSpy)
        }

        @Test func focusStart_startsNoise() {
            let (store, spy) = self.makeStore()
            store.start()
            #expect(spy.startCallCount == 1)
            #expect(spy.lastStartVolume == 0.5)
        }

        @Test func pause_stopsNoise() {
            let (store, spy) = self.makeStore()
            store.start()
            store.pause()
            #expect(spy.stopCallCount == 1)
        }

        @Test func resume_restartsNoise() {
            let (store, spy) = self.makeStore()
            store.start()
            store.pause()
            store.resume()
            #expect(spy.startCallCount == 2)
        }

        @Test func reset_stopsNoise() {
            let (store, spy) = self.makeStore()
            store.start()
            store.reset()
            #expect(spy.stopCallCount >= 1)
        }

        @Test func breakSession_stopsNoise() {
            let (store, spy) = self.makeStore()
            let now = Date()
            store.now = now
            store.snapshot = TimerSnapshot(
                sessionType: .focus,
                timerState: .running,
                startedAt: now.addingTimeInterval(-1500),
                endDate: now.addingTimeInterval(-1),
                pausedRemainingSec: nil,
                completedFocusCount: 0,
                boundaryStopPolicy: .none
            )

            store.handleScenePhaseChange(.active)

            // After focus → short break transition, noise should stop
            #expect(store.sessionType == .shortBreak)
            #expect(spy.stopCallCount >= 1)
        }

        @Test func noiseDisabled_doesNotStart() {
            let (store, spy) = self.makeStore()
            store.config.ambientNoiseEnabled = false
            store.start()
            #expect(spy.startCallCount == 0)
            #expect(spy.stopCallCount >= 1)
        }

        @Test func setVolume_updatesService() {
            let (store, spy) = self.makeStore()
            store.start()
            store.updateAmbientNoiseVolume(0.8)
            #expect(spy.lastSetVolume == 0.8)
        }
    }
#endif

@Suite("PulseVisual")
struct PulseVisualTests {
    @Test func heartbeatEnvelope_peakNearPhaseStart() {
        let peakIntensity = PulseVisual.heartbeatEnvelope(phase: 0.08)
        let midIntensity = PulseVisual.heartbeatEnvelope(phase: 0.5)

        #expect(peakIntensity > 0.8)
        #expect(midIntensity < 0.1)
    }

    @Test func heartbeatEnvelope_hasSecondPeak() {
        let secondPeak = PulseVisual.heartbeatEnvelope(phase: 0.18)
        let valley = PulseVisual.heartbeatEnvelope(phase: 0.4)

        #expect(secondPeak > valley)
    }

    @Test func heartbeatEnvelope_clampsToOne() {
        for phase in stride(from: 0.0, through: 1.0, by: 0.01) {
            let value = PulseVisual.heartbeatEnvelope(phase: phase)
            #expect(value >= 0.0)
            #expect(value <= 1.0)
        }
    }

    @Test func rippleIntensity_highAtWaveFront() {
        let atFront = PulseVisual.rippleIntensity(distance: 0.14, beatPhase: 0.1, beatPeriod: 1.0)
        let farFromFront = PulseVisual.rippleIntensity(distance: 0.8, beatPhase: 0.1, beatPeriod: 1.0)

        #expect(atFront > farFromFront)
    }

    @Test func sessionAlpha_focusAlwaysOne() {
        #expect(PulseVisual.sessionAlpha(sessionType: .focus, progress: 0.0) == 1.0)
        #expect(PulseVisual.sessionAlpha(sessionType: .focus, progress: 0.5) == 1.0)
        #expect(PulseVisual.sessionAlpha(sessionType: .focus, progress: 1.0) == 1.0)
    }

    @Test func sessionAlpha_breakDecaysButNeverZero() {
        let start = PulseVisual.sessionAlpha(sessionType: .shortBreak, progress: 0.0)
        let mid = PulseVisual.sessionAlpha(sessionType: .shortBreak, progress: 0.5)
        let end = PulseVisual.sessionAlpha(sessionType: .shortBreak, progress: 1.0)

        #expect(start == 1.0)
        #expect(mid < start)
        #expect(end < mid)
        #expect(end >= 0.05)
    }
}

@Suite("WatchSyncPayload")
struct WatchSyncPayloadTests {
    @Test func idleState_excludesNilOptionals() {
        let snapshot = TimerSnapshot.initial
        let context = WatchSyncPayload.build(snapshot: snapshot, config: .default, now: Date())

        #expect(context["endDateEpoch"] == nil)
        #expect(context["pausedRemainingSec"] == nil)
        #expect(context["timerState"] as? String == "idle")
        #expect(context["sessionType"] as? String == "focus")
    }

    @Test func idleState_includesSessionDuration() {
        let snapshot = TimerSnapshot.initial
        let config = TimerConfig.default
        let context = WatchSyncPayload.build(snapshot: snapshot, config: config, now: Date())

        #expect(context["sessionDurationSec"] as? Int == config.focusDurationSec)
    }

    @Test func runningState_includesEndDate() {
        var snapshot = TimerSnapshot.initial
        let now = Date()
        snapshot.timerState = .running
        snapshot.endDate = now.addingTimeInterval(1500)
        let context = WatchSyncPayload.build(snapshot: snapshot, config: .default, now: now)

        #expect(context["endDateEpoch"] as? Double != nil)
        #expect(context["pausedRemainingSec"] == nil)
        #expect(context["timerState"] as? String == "running")
    }

    @Test func pausedState_includesPausedRemaining() {
        var snapshot = TimerSnapshot.initial
        snapshot.timerState = .paused
        snapshot.pausedRemainingSec = 600
        let context = WatchSyncPayload.build(snapshot: snapshot, config: .default, now: Date())

        #expect(context["pausedRemainingSec"] as? Int == 600)
        #expect(context["endDateEpoch"] == nil)
        #expect(context["timerState"] as? String == "paused")
    }

    @Test func allValues_arePlistCompatibleTypes() {
        var snapshot = TimerSnapshot.initial
        snapshot.timerState = .running
        snapshot.endDate = Date().addingTimeInterval(1500)
        let context = WatchSyncPayload.build(snapshot: snapshot, config: .default, now: Date())

        for (key, value) in context {
            let isValid = value is String || value is Int || value is Double
            #expect(isValid, "Key '\(key)' has non-plist type: \(type(of: value))")
        }
    }
}
