# Test Strategy Review (Codex gpt-5.3)

**Date:** 2026-02-26
**Reviewer:** Codex (gpt-5.3-codex)
**Current:** 53 unit tests + 4 macOS UI tests + 1 launch test

## 1. Current Coverage Evaluation

### Well-Tested

- `TimerEngine`: basic transitions, stop policies
- `TimerStore`: basic state transitions (start/pause/resume/reset/skip)
- Notification spy: schedule/cancel coordination
- Session history: record saving on complete/skip
- AmbientNoise: start/stop lifecycle branching
- Localization: English baseline + Japanese locale verification (9 tests)
- Watch payload: `WatchSyncPayload.build()` output structure

### Gaps

| Area | Gap |
|------|-----|
| `TimerStore` | Multi-boundary `while` loop restoration, `handleConfigChangeWhileActiveTimer` clamp, `pause`/`resume` no-op guards |
| Settings persistence | `loadPreferencesIfNeeded`, `persistPreferences`, `applyPreferences` min-value correction, error path (`lastErrorMessage`) |
| Watch roundtrip | `handleWatchCommand` (3 commands), watch-side state application, send failure handling |
| iOS UI tests | Only launch test exists; no interaction flow tests |
| Service implementations | `NotificationService`, `FocusModeService`, `LiveActivityService` real implementations untested |
| Settings/History screens | No view-level tests |

## 2. Recommended Unit Tests

### TimerEngine

- `progress` boundaries: duration=0, remaining<0, remaining>duration
- `remainingSeconds`: endDate=nil, already elapsed, paused with nil
- `dueToSkip` branching in `shouldStopAtBoundary`

### TimerStore

- `pause`/`resume` no-op guards (pause when idle, resume when running)
- `skip` from idle/running/paused states
- Multi-session restoration (`while` loop: timer expired through multiple sessions)
- `handleConfigChangeWhileActiveTimer` duration clamp
- `handleWatchCommand` for all 3 commands (primaryAction, reset, skip)

### Persistence

- `applyPreferences` min-value correction
- `persistPreferences` full field roundtrip
- Save failure → `lastErrorMessage` set

## 3. Integration Tests

| Priority | Test | Approach |
|----------|------|----------|
| High | `TimerStore + NotificationService` | Verify schedule/cancel across start→pause→resume→auto-transition |
| High | `TimerStore + SwiftData` | Settings change → "restart" → restore with in-memory ModelContainer |
| Medium | `TimerStore + WatchSyncServicing` | Verify sync called on each state transition |

## 4. E2E / UI Test Strategy

### iOS (highest gap)

- Smoke test: Start → Pause → Resume → Reset
- Menu navigation: ... menu → History sheet → dismiss → ... menu → Settings sheet → dismiss
- Settings change reflection: change focus duration, verify display update

### macOS (extend existing)

- Settings/History sheet flow via ... menu
- Boundary stop policy UI operation
- Restore after relaunch

### Shared Infrastructure

- Launch argument for short durations (e.g., `--focus-duration 5`)
- Launch argument to disable animations
- In-memory SwiftData for test isolation

### MenuBar Limitation

- XCUITest cannot click MenuBarExtra status items (not hittable)
- Test via shared `TimerStore` integration instead

## 5. Priority Order (Cost-Effectiveness)

| Priority | Test Category | Effort | Value |
|----------|--------------|--------|-------|
| 1 | `TimerStore` boundary/restore/config-change unit tests | Low | High |
| 2 | iOS UI smoke test (1 flow: Start→Pause→Resume→Reset) | Medium | High |
| 3 | Settings persistence integration test (in-memory SwiftData) | Low | Medium |
| 4 | `TimerStore + NotificationService` integration test | Low | Medium |
| 5 | Watch roundtrip integration test | Medium | Medium |
| 6 | Service implementation detail tests | High | Low |

## Notes

- `skip` advancing focus count is confirmed intentional behavior (committed in `8b098db`)
- Services behind protocols are already testable via spies — focus on integration over implementation testing
- iOS 26 Liquid Glass toolbar items are not in the accessibility tree — UI tests may require coordinate-based taps
