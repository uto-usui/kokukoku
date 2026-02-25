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
