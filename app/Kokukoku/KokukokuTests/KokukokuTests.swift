import Foundation
@testable import Kokukoku
import SwiftUI
import Testing

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
}
