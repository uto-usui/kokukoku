# Test Expansion Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fill test coverage gaps identified by Codex review — unit tests for TimerEngine/TimerStore edge cases, persistence integration tests, notification integration test, and watch command tests.

**Architecture:** All new tests go into `KokukokuTests.swift` using Swift Testing (`@Test`, `#expect`). Existing spy classes are reused. In-memory `ModelContext` helper (`makeInMemoryModelContext`) already exists.

**Tech Stack:** Swift Testing, SwiftData (in-memory), existing spy protocols

**Test file:** `app/Kokukoku/KokukokuTests/KokukokuTests.swift`

---

### Task 1: TimerEngine Edge Case Tests

Add a new `@Suite("TimerEngine – Edge Cases")` section with boundary/edge tests.

**Tests to add:**

```swift
// progress boundaries
@Test func progress_durationZero_returnsOne()
// duration=0 → progress returns 1.0
TimerEngine.progress(durationSec: 0, remainingSec: 0) == 1.0

@Test func progress_remainingExceedsDuration_returnsZero()
// remaining > duration → progress clamps to 0.0
TimerEngine.progress(durationSec: 100, remainingSec: 200) == 0.0

@Test func progress_remainingNegative_returnsOne()
// negative remaining → progress clamps to 1.0
TimerEngine.progress(durationSec: 100, remainingSec: -10) == 1.0

// remainingSeconds edge cases
@Test func remainingSeconds_runningWithNilEndDate_returnsFallback()
// running state with endDate=nil → returns fallbackDurationSec
TimerEngine.remainingSeconds(timerState: .running, endDate: nil, ..., fallbackDurationSec: 300) == 300

@Test func remainingSeconds_runningAlreadyElapsed_returnsZero()
// endDate in the past → returns 0
TimerEngine.remainingSeconds(timerState: .running, endDate: pastDate, ...) == 0

@Test func remainingSeconds_pausedWithNilPausedRemaining_returnsFallback()
// paused with nil pausedRemainingSec → returns fallback
TimerEngine.remainingSeconds(timerState: .paused, ..., pausedRemainingSec: nil, fallbackDurationSec: 300) == 300

// shouldStopAtBoundary: dueToSkip branching
@Test func stopPolicy_skipWithAutoStart_doesNotStop()
// dueToSkip=true, autoStart=true → shouldStop=false
TimerEngine.shouldStopAtBoundary(policy: .stopAtNextBoundary, ..., dueToSkip: true, autoStart: true).shouldStop == false

@Test func stopPolicy_skipWithoutAutoStart_stops()
// dueToSkip=true, autoStart=false → shouldStop=true
TimerEngine.shouldStopAtBoundary(policy: .none, ..., dueToSkip: true, autoStart: false).shouldStop == true
```

**Verify:** `make test-macos` passes.

---

### Task 2: TimerStore Guard & Config Change Tests

Add tests to the existing `TimerStoreTests` struct.

**Tests to add:**

```swift
// pause/resume no-op guards
@Test func pause_whenIdle_isNoOp()
// store in idle state → pause() doesn't change state
store.pause(); #expect(store.timerState == .idle)

@Test func pause_whenPaused_isNoOp()
// store in paused state → pause() doesn't change state
store.pause(); #expect(store.timerState == .paused)

@Test func resume_whenIdle_isNoOp()
// store in idle state → resume() doesn't change state
store.resume(); #expect(store.timerState == .idle)

@Test func resume_whenRunning_isNoOp()
// store in running state → resume() doesn't change state
store.resume(); #expect(store.timerState == .running)

// skip from idle
@Test func skip_whenIdle_transitionsToNextSession()
// idle focus → skip → shortBreak (still idle since no running session)
// This tests that skip works even when not running

// handleConfigChangeWhileActiveTimer: duration clamp
@Test func configChange_whileRunning_clampsRemainingToNewDuration()
// running with 1400s remaining, change focus to 5min (300s) → endDate clamped
store.snapshot = running state with long remaining
store.updateFocusMinutes(5)
// remaining should be <= 300

@Test func configChange_whilePaused_clampsRemainingToNewDuration()
// paused with 1400s remaining, change focus to 5min (300s) → pausedRemainingSec clamped
store.snapshot = paused with 1400s remaining
store.updateFocusMinutes(5)
#expect(store.remainingSeconds <= 300)

// multi-boundary while loop restoration
@Test func restore_multipleSessionsElapsed_advancesMultipleSessions()
// running focus started 3000s ago (2 full focus sessions elapsed)
// endDate far in the past → processElapsedSessionsIfNeeded loops through multiple boundaries
```

**Verify:** `make test-macos` passes.

---

### Task 3: Persistence Integration Tests

Add a new `@Suite("Persistence")` section testing SwiftData integration with in-memory store.

**Tests to add:**

```swift
@MainActor
@Suite("Persistence")
struct PersistenceTests {
    // Reuse existing makeInMemoryModelContext() pattern

    @Test func loadPreferences_createsDefaultsWhenEmpty()
    // bind to empty modelContext → preferences created with defaults
    // verify config matches TimerConfig.default

    @Test func persistPreferences_fullFieldRoundtrip()
    // bind → change all config fields → persist → create new store → bind to same context → verify all fields match

    @Test func applyPreferences_minValueCorrection()
    // create UserTimerPreferences with focusDurationSec=30 (below 60 min)
    // applyPreferences → config.focusDurationSec should be 60 (clamped)

    @Test func persistPreferences_saveFail_setsErrorMessage()
    // This is hard to test without mocking ModelContext, so SKIP this one

    @Test func loadPreferences_setsConfigAndBoundaryPolicy()
    // create prefs with stopAtLongBreak → bind → verify snapshot.boundaryStopPolicy == .stopAtLongBreak
}
```

**Verify:** `make test-macos` passes.

---

### Task 4: TimerStore + NotificationService Integration Test

Add a new `@Suite("Notification Integration")` section testing the full notification lifecycle across state transitions.

**Tests to add:**

```swift
@MainActor
@Suite("Notification Integration")
struct NotificationIntegrationTests {
    @Test func fullCycle_startPauseResumeAutoTransition_schedulesAndCancelsCorrectly() async
    // start → schedule (1)
    // pause → cancel (1)
    // resume → schedule (2)
    // simulate session end (set endDate in past, handleScenePhaseChange) → cancel (2) + schedule for next session (3)
    // Verify: scheduleCallCount == 3, cancelCallCount == 2
    // Verify: lastScheduledSessionType changes from .focus to .shortBreak

    @Test func notificationSound_reflectsEffectiveSoundSetting() async
    // start with sound on → lastScheduledSoundEnabled == true
    // change respectFocusMode to true, set focus mode active → reschedule with soundEnabled == false
}
```

**Verify:** `make test-macos` passes.

---

### Task 5: Watch Command Tests

Add a new `@Suite("Watch Commands")` section testing handleWatchCommand for all 3 commands.

**Requires:** A `WatchSyncServiceSpy` for verifying sync calls.

```swift
@MainActor
private final class WatchSyncServiceSpy: WatchSyncServicing {
    var activateCallCount = 0
    var syncCallCount = 0
    var lastSyncSnapshot: TimerSnapshot?
    var commandHandler: (@MainActor (WatchTimerCommand) -> Void)?

    func activate() { activateCallCount += 1 }
    func setCommandHandler(_ handler: (@MainActor (WatchTimerCommand) -> Void)?) {
        commandHandler = handler
    }
    func sync(snapshot: TimerSnapshot, config: TimerConfig, now: Date) {
        syncCallCount += 1
        lastSyncSnapshot = snapshot
    }
}

@MainActor
@Suite("Watch Commands")
struct WatchCommandTests {
    @Test func primaryAction_fromIdle_startsTimer() async
    // handleWatchCommand(.primaryAction) when idle → running

    @Test func primaryAction_fromRunning_pausesTimer() async
    // handleWatchCommand(.primaryAction) when running → paused

    @Test func primaryAction_fromPaused_resumesTimer() async
    // handleWatchCommand(.primaryAction) when paused → running

    @Test func reset_fromPaused_resetsToIdle()
    // handleWatchCommand(.reset) → idle, focus, completedFocusCount == 0

    @Test func skip_fromRunning_advancesToNextSession()
    // handleWatchCommand(.skip) when running focus → shortBreak

    @Test func watchSync_calledOnStateTransitions() async
    // Use WatchSyncServiceSpy, verify syncCallCount increases on start/pause/reset
}
```

**Verify:** `make test-macos` passes.

---

## Verification Gate

After all tasks complete:
```bash
make ci   # lint + test-macos (all tests) + build-ios
```
