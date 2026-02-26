// swiftlint:disable file_length
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

@MainActor
private final class WatchSyncServiceSpy: WatchSyncServicing {
    var activateCallCount = 0
    var syncCallCount = 0
    var lastSyncSnapshot: TimerSnapshot?
    var commandHandler: (@MainActor (WatchTimerCommand) -> Void)?

    func activate() {
        self.activateCallCount += 1
    }

    func setCommandHandler(_ handler: (@MainActor (WatchTimerCommand) -> Void)?) {
        self.commandHandler = handler
    }

    func sync(snapshot: TimerSnapshot, config: TimerConfig, now: Date) {
        self.syncCallCount += 1
        self.lastSyncSnapshot = snapshot
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

@Suite("TimerEngine – Edge Cases")
struct TimerEngineEdgeCaseTests {
    @Test func progress_durationZero_returnsOne() {
        #expect(TimerEngine.progress(durationSec: 0, remainingSec: 0) == 1.0)
    }

    @Test func progress_remainingExceedsDuration_returnsZero() {
        #expect(TimerEngine.progress(durationSec: 100, remainingSec: 200) == 0.0)
    }

    @Test func progress_remainingNegative_clampsToOne() {
        #expect(TimerEngine.progress(durationSec: 100, remainingSec: -10) == 1.0)
    }

    @Test func remainingSeconds_runningWithNilEndDate_returnsFallback() {
        let remaining = TimerEngine.remainingSeconds(
            timerState: .running,
            endDate: nil,
            pausedRemainingSec: nil,
            now: Date(),
            fallbackDurationSec: 300
        )
        #expect(remaining == 300)
    }

    @Test func remainingSeconds_runningAlreadyElapsed_returnsZero() {
        let now = Date()
        let remaining = TimerEngine.remainingSeconds(
            timerState: .running,
            endDate: now.addingTimeInterval(-60),
            pausedRemainingSec: nil,
            now: now,
            fallbackDurationSec: 300
        )
        #expect(remaining == 0)
    }

    @Test func remainingSeconds_pausedWithNilPausedRemaining_returnsFallback() {
        let remaining = TimerEngine.remainingSeconds(
            timerState: .paused,
            endDate: nil,
            pausedRemainingSec: nil,
            now: Date(),
            fallbackDurationSec: 300
        )
        #expect(remaining == 300)
    }

    @Test func stopPolicy_skipWithAutoStart_doesNotStop() {
        let decision = TimerEngine.shouldStopAtBoundary(
            policy: .stopAtNextBoundary,
            nextSessionType: .shortBreak,
            dueToSkip: true,
            autoStart: true
        )
        #expect(!decision.shouldStop)
        #expect(!decision.consumePolicy)
    }

    @Test func stopPolicy_skipWithoutAutoStart_stops() {
        let decision = TimerEngine.shouldStopAtBoundary(
            policy: .none,
            nextSessionType: .shortBreak,
            dueToSkip: true,
            autoStart: false
        )
        #expect(decision.shouldStop)
        #expect(!decision.consumePolicy)
    }
}

@MainActor
// swiftlint:disable:next type_body_length
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

    // MARK: - Guard Tests (no-op when wrong state)

    @Test func pause_whenIdle_isNoOp() {
        let store = TimerStore()
        #expect(store.timerState == .idle)
        store.pause()
        #expect(store.timerState == .idle)
    }

    @Test func pause_whenAlreadyPaused_isNoOp() {
        let store = TimerStore()
        let now = Date()
        store.now = now
        store.snapshot = TimerSnapshot(
            sessionType: .focus,
            timerState: .paused,
            startedAt: now.addingTimeInterval(-300),
            endDate: nil,
            pausedRemainingSec: 200,
            completedFocusCount: 0,
            boundaryStopPolicy: .none
        )
        store.pause()
        #expect(store.timerState == .paused)
        #expect(store.remainingSeconds == 200)
    }

    @Test func resume_whenIdle_isNoOp() {
        let store = TimerStore()
        #expect(store.timerState == .idle)
        store.resume()
        #expect(store.timerState == .idle)
    }

    @Test func resume_whenRunning_isNoOp() {
        let store = TimerStore()
        let now = Date()
        store.now = now
        store.snapshot = TimerSnapshot(
            sessionType: .focus,
            timerState: .running,
            startedAt: now.addingTimeInterval(-300),
            endDate: now.addingTimeInterval(600),
            pausedRemainingSec: nil,
            completedFocusCount: 0,
            boundaryStopPolicy: .none
        )
        store.resume()
        #expect(store.timerState == .running)
    }

    // MARK: - Config Change While Active

    @Test func configChange_whileRunning_clampsRemainingToNewDuration() {
        let store = TimerStore(notificationService: NotificationServiceSpy(requestedAuthorizationState: .denied))
        let now = Date()
        store.now = now
        store.config = TimerConfig.default // 25 min focus
        store.snapshot = TimerSnapshot(
            sessionType: .focus,
            timerState: .running,
            startedAt: now.addingTimeInterval(-100),
            endDate: now.addingTimeInterval(1400), // ~1400s remaining
            pausedRemainingSec: nil,
            completedFocusCount: 0,
            boundaryStopPolicy: .none
        )

        store.updateFocusMinutes(5) // 300s
        // handleConfigChangeWhileActiveTimer sets endDate from Date(), so sync now
        store.now = Date()
        #expect(store.remainingSeconds <= 300)
        #expect(store.timerState == .running)
    }

    @Test func configChange_whilePaused_clampsRemainingToNewDuration() {
        let store = TimerStore()
        store.config = TimerConfig.default // 25 min focus
        store.snapshot = TimerSnapshot(
            sessionType: .focus,
            timerState: .paused,
            startedAt: Date().addingTimeInterval(-100),
            endDate: nil,
            pausedRemainingSec: 1400,
            completedFocusCount: 0,
            boundaryStopPolicy: .none
        )

        store.updateFocusMinutes(5) // 300s
        #expect(store.remainingSeconds <= 300)
        #expect(store.timerState == .paused)
    }

    @Test func configChange_whenIdle_doesNotCrash() {
        let store = TimerStore()
        store.config = TimerConfig.default
        store.updateFocusMinutes(10)
        #expect(store.timerState == .idle)
    }

    // MARK: - Multi-Boundary Restoration

    @Test func restore_multipleSessionsElapsed_advancesMultipleSessions() {
        let store = TimerStore()
        var config = TimerConfig.default
        config.focusDurationSec = 60 // 1 min focus
        config.shortBreakDurationSec = 60 // 1 min break
        store.config = config

        let realNow = Date()
        store.snapshot = TimerSnapshot(
            sessionType: .focus,
            timerState: .running,
            startedAt: realNow.addingTimeInterval(-150),
            endDate: realNow.addingTimeInterval(-90), // Focus ended 90s ago
            pausedRemainingSec: nil,
            completedFocusCount: 0,
            boundaryStopPolicy: .none
        )

        store.handleScenePhaseChange(.active)

        #expect(store.completedFocusCount == 1)
        #expect(store.sessionType == .focus)
        #expect(store.timerState == .running)
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

@MainActor
@Suite("Persistence")
struct PersistenceTests {
    private static func makeInMemoryModelContext() throws -> ModelContext {
        let schema = Schema([
            SessionRecord.self,
            UserTimerPreferences.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        return ModelContext(container)
    }

    @Test func loadPreferences_createsDefaultsWhenEmpty() throws {
        let store = TimerStore(
            notificationService: NotificationServiceSpy(requestedAuthorizationState: .denied)
        )
        let modelContext = try Self.makeInMemoryModelContext()
        store.bind(modelContext: modelContext)

        let prefs = try modelContext.fetch(FetchDescriptor<UserTimerPreferences>())
        #expect(prefs.count == 1)
        #expect(prefs.first?.focusDurationSec == TimerConfig.default.focusDurationSec)
        #expect(prefs.first?.shortBreakDurationSec == TimerConfig.default.shortBreakDurationSec)
        #expect(prefs.first?.autoStart == TimerConfig.default.autoStart)
    }

    @Test func persistPreferences_fullFieldRoundtrip() throws {
        let store = TimerStore(
            notificationService: NotificationServiceSpy(requestedAuthorizationState: .denied)
        )
        let modelContext = try Self.makeInMemoryModelContext()
        store.bind(modelContext: modelContext)

        store.config.focusDurationSec = 30 * 60
        store.config.shortBreakDurationSec = 10 * 60
        store.config.longBreakDurationSec = 20 * 60
        store.config.longBreakFrequency = 6
        store.config.autoStart = false
        store.config.notificationSoundEnabled = false
        store.config.respectFocusMode = false
        store.config.ambientNoiseEnabled = true
        store.config.ambientNoiseVolume = 0.8
        store.config.narrativeModeEnabled = true
        store.snapshot.boundaryStopPolicy = .stopAtLongBreak
        store.persistPreferences()

        let store2 = TimerStore(
            notificationService: NotificationServiceSpy(requestedAuthorizationState: .denied)
        )
        store2.bind(modelContext: modelContext)

        #expect(store2.config.focusDurationSec == 30 * 60)
        #expect(store2.config.shortBreakDurationSec == 10 * 60)
        #expect(store2.config.longBreakDurationSec == 20 * 60)
        #expect(store2.config.longBreakFrequency == 6)
        #expect(store2.config.autoStart == false)
        #expect(store2.config.notificationSoundEnabled == false)
        #expect(store2.config.respectFocusMode == false)
        #expect(store2.config.ambientNoiseEnabled == true)
        #expect(store2.config.ambientNoiseVolume == 0.8)
        #expect(store2.config.narrativeModeEnabled == true)
        #expect(store2.boundaryStopPolicy == .stopAtLongBreak)
    }

    @Test func applyPreferences_minValueCorrection() {
        let store = TimerStore()
        let prefs = UserTimerPreferences(
            focusDurationSec: 30,
            shortBreakDurationSec: 10,
            longBreakDurationSec: 45,
            longBreakFrequency: 0,
            autoStart: true,
            notificationSoundEnabled: true,
            boundaryStopPolicyRaw: BoundaryStopPolicy.none.rawValue
        )

        store.applyPreferences(prefs)

        #expect(store.config.focusDurationSec == 60)
        #expect(store.config.shortBreakDurationSec == 60)
        #expect(store.config.longBreakDurationSec == 60)
        #expect(store.config.longBreakFrequency == 1)
    }

    @Test func loadPreferences_setsConfigAndBoundaryPolicy() throws {
        let modelContext = try Self.makeInMemoryModelContext()

        let prefs = UserTimerPreferences(
            focusDurationSec: 20 * 60,
            shortBreakDurationSec: 3 * 60,
            longBreakDurationSec: 10 * 60,
            longBreakFrequency: 3,
            autoStart: false,
            notificationSoundEnabled: false,
            boundaryStopPolicyRaw: BoundaryStopPolicy.stopAtLongBreak.rawValue
        )
        modelContext.insert(prefs)
        try modelContext.save()

        let store = TimerStore(
            notificationService: NotificationServiceSpy(requestedAuthorizationState: .denied)
        )
        store.bind(modelContext: modelContext)

        #expect(store.config.focusDurationSec == 20 * 60)
        #expect(store.config.longBreakFrequency == 3)
        #expect(store.config.autoStart == false)
        #expect(store.boundaryStopPolicy == .stopAtLongBreak)
    }
}

@MainActor
@Suite("Notification Integration")
struct NotificationIntegrationTests {
    private func drainMainActorTaskQueue() async {
        await Task.yield()
        await Task.yield()
        await Task.yield()
        await Task.yield()
    }

    @Test func fullCycle_startPauseResumeAutoTransition_schedulesAndCancelsCorrectly() async {
        let notificationSpy = NotificationServiceSpy()
        let store = TimerStore(notificationService: notificationSpy)

        store.start()
        await self.drainMainActorTaskQueue()
        #expect(notificationSpy.scheduleCallCount == 1)
        #expect(notificationSpy.lastScheduledSessionType == .focus)

        store.pause()
        let cancelAfterPause = notificationSpy.cancelCallCount
        #expect(cancelAfterPause >= 1)

        store.resume()
        await self.drainMainActorTaskQueue()
        #expect(notificationSpy.scheduleCallCount == 2)

        let now = Date()
        store.now = now
        store.snapshot.endDate = now.addingTimeInterval(-1)
        store.snapshot.startedAt = now.addingTimeInterval(-1500)
        store.handleScenePhaseChange(.active)
        await self.drainMainActorTaskQueue()

        #expect(notificationSpy.cancelCallCount > cancelAfterPause)
        #expect(notificationSpy.scheduleCallCount >= 3)
        #expect(notificationSpy.lastScheduledSessionType == .shortBreak)
    }

    @Test func notificationSound_reflectsFocusModeStatus() async {
        let notificationSpy = NotificationServiceSpy()
        let focusSpy = FocusModeServiceSpy()
        focusSpy.refreshedStatus = FocusModeStatus(authorizationState: .authorized, isFocused: false)
        let store = TimerStore(notificationService: notificationSpy, focusModeService: focusSpy)

        store.config.notificationSoundEnabled = true
        store.config.respectFocusMode = true
        store.start()
        await self.drainMainActorTaskQueue()
        #expect(notificationSpy.lastScheduledSoundEnabled == true)
        let scheduleCountBeforeFocusChange = notificationSpy.scheduleCallCount

        focusSpy.refreshedStatus = FocusModeStatus(authorizationState: .authorized, isFocused: true)
        store.handleScenePhaseChange(.active)

        for _ in 0 ..< 8 {
            await Task.yield()
        }

        #expect(store.focusModeStatus.isFocused == true)
        #expect(store.effectiveNotificationSoundEnabled == false)
        #expect(notificationSpy.scheduleCallCount > scheduleCountBeforeFocusChange)
        #expect(notificationSpy.lastScheduledSoundEnabled == false)
    }
}

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

@Suite("Localization")
struct LocalizationTests {
    // MARK: - SessionType.title

    @Test func sessionType_titleReturnsExpectedEnglish() {
        #expect(SessionType.focus.title == "Focus")
        #expect(SessionType.shortBreak.title == "Short Break")
        #expect(SessionType.longBreak.title == "Long Break")
    }

    // MARK: - BoundaryStopPolicy.title

    @Test func boundaryStopPolicy_titleReturnsExpectedEnglish() {
        #expect(BoundaryStopPolicy.none.title == "No Boundary Stop")
        #expect(BoundaryStopPolicy.stopAtNextBoundary.title == "Stop at Next Boundary")
        #expect(BoundaryStopPolicy.stopAtLongBreak.title == "Stop at Long Break")
    }

    // MARK: - primaryActionTitle

    @MainActor
    @Test func primaryActionTitle_returnsCorrectTitlePerState() {
        let store = TimerStore()

        #expect(store.primaryActionTitle == "Start")

        store.snapshot.timerState = .running
        #expect(store.primaryActionTitle == "Pause")

        store.snapshot.timerState = .paused
        #expect(store.primaryActionTitle == "Resume")
    }

    // MARK: - focusCycleStatusText

    @MainActor
    @Test func focusCycleStatusText_formatsCorrectly() {
        let store = TimerStore()
        store.config.longBreakFrequency = 4
        store.snapshot.completedFocusCount = 0
        #expect(store.focusCycleStatusText == "Cycle: 0/4")

        store.snapshot.completedFocusCount = 3
        #expect(store.focusCycleStatusText == "Cycle: 3/4")

        store.snapshot.completedFocusCount = 4
        #expect(store.focusCycleStatusText == "Cycle: 0/4")
    }

    // MARK: - Japanese Locale Verification

    /// Loads the ja.lproj sub-bundle from the host app bundle for reliable locale testing.
    private static var jaBundle: Bundle {
        let hostBundle = Bundle(for: TimerStore.self)
        guard let url = hostBundle.url(forResource: "ja", withExtension: "lproj"),
              let bundle = Bundle(url: url)
        else {
            preconditionFailure("ja.lproj not found in \(hostBundle.bundlePath)")
        }
        return bundle
    }

    private func ja(_ key: String) -> String {
        NSLocalizedString(key, bundle: Self.jaBundle, comment: "")
    }

    @Test func japaneseLocale_sessionTypeTitles() {
        #expect(self.ja("Focus") == "集中")
        #expect(self.ja("Short Break") == "小休憩")
        #expect(self.ja("Long Break") == "長休憩")
    }

    @Test func japaneseLocale_actionTitles() {
        #expect(self.ja("Start") == "スタート")
        #expect(self.ja("Pause") == "一時停止")
        #expect(self.ja("Resume") == "再開")
    }

    @Test func japaneseLocale_uiLabels() {
        #expect(self.ja("Settings") == "設定")
        #expect(self.ja("History") == "履歴")
        #expect(self.ja("Reset") == "リセット")
        #expect(self.ja("Skip") == "スキップ")
    }

    @Test func japaneseLocale_notificationStrings() {
        #expect(self.ja("Focus completed") == "集中セッション完了")
        #expect(self.ja("Time for a break.") == "休憩の時間です。")
        #expect(self.ja("Time to focus.") == "集中の時間です。")
    }

    @Test func japaneseLocale_boundaryStopPolicyTitles() {
        #expect(self.ja("No Boundary Stop") == "自動継続")
        #expect(self.ja("Stop at Next Boundary") == "次の区切りで停止")
        #expect(self.ja("Stop at Long Break") == "長休憩で停止")
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

        #expect(context["endDateEpoch"] is Double)
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

@MainActor
@Suite("Watch Commands")
struct WatchCommandTests {
    private func drainMainActorTaskQueue() async {
        await Task.yield()
        await Task.yield()
    }

    private func makeStore() -> (TimerStore, WatchSyncServiceSpy) {
        let watchSpy = WatchSyncServiceSpy()
        let store = TimerStore(
            notificationService: NotificationServiceSpy(requestedAuthorizationState: .denied),
            focusModeService: FocusModeServiceSpy(),
            watchConnectivityService: watchSpy
        )
        return (store, watchSpy)
    }

    @Test func primaryAction_fromIdle_startsTimer() async {
        let (store, _) = self.makeStore()
        #expect(store.timerState == .idle)

        store.handleWatchCommand(.primaryAction)
        await self.drainMainActorTaskQueue()

        #expect(store.timerState == .running)
    }

    @Test func primaryAction_fromRunning_pausesTimer() async {
        let (store, _) = self.makeStore()
        store.handleWatchCommand(.primaryAction)
        await self.drainMainActorTaskQueue()
        #expect(store.timerState == .running)

        store.handleWatchCommand(.primaryAction)
        #expect(store.timerState == .paused)
    }

    @Test func primaryAction_fromPaused_resumesTimer() async {
        let (store, _) = self.makeStore()
        store.handleWatchCommand(.primaryAction)
        await self.drainMainActorTaskQueue()
        store.handleWatchCommand(.primaryAction)
        #expect(store.timerState == .paused)

        store.handleWatchCommand(.primaryAction)
        await self.drainMainActorTaskQueue()
        #expect(store.timerState == .running)
    }

    @Test func reset_resetsToIdleFocus() async {
        let (store, _) = self.makeStore()
        store.handleWatchCommand(.primaryAction)
        await self.drainMainActorTaskQueue()
        #expect(store.timerState == .running)

        store.handleWatchCommand(.reset)
        #expect(store.timerState == .idle)
        #expect(store.sessionType == .focus)
        #expect(store.completedFocusCount == 0)
    }

    @Test func skip_fromRunning_advancesToNextSession() {
        let (store, _) = self.makeStore()
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

        store.handleWatchCommand(.skip)
        #expect(store.sessionType == .shortBreak)
        #expect(store.completedFocusCount == 1)
    }

    @Test func watchSync_calledOnStateTransitions() async {
        let (store, watchSpy) = self.makeStore()
        let initialSyncCount = watchSpy.syncCallCount

        store.handleWatchCommand(.primaryAction)
        await self.drainMainActorTaskQueue()
        #expect(watchSpy.syncCallCount > initialSyncCount)
        let afterStart = watchSpy.syncCallCount

        store.handleWatchCommand(.primaryAction)
        #expect(watchSpy.syncCallCount > afterStart)
        let afterPause = watchSpy.syncCallCount

        store.handleWatchCommand(.reset)
        #expect(watchSpy.syncCallCount > afterPause)
    }
}
