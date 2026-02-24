# Kokukoku MVP Tasks

## M0. Planning Lock (Before Implementation)
- [ ] Finalize Phase 1 scope boundaries from `PLAN.md`.
- [ ] Lock UI composition rules:
  - [ ] Navigation model (`NavigationStack` on iOS, `NavigationSplitView` on macOS)
  - [ ] Primary/secondary button styles
  - [ ] Timer typography (`monospacedDigit`)
- [ ] Lock styling rules:
  - [ ] Semantic color-first policy
  - [ ] Session accent tokens (focus/shortBreak/longBreak)
- [ ] Lock notification default: `Sound ON` with optional `Silent`.

## M1. Domain and Timer Engine
- [ ] Define `TimerState`, `SessionType`, `TimerConfig`, `TimerSnapshot`.
- [ ] Define `BoundaryStopPolicy`:
  - [ ] none
  - [ ] stopAtNextBoundary
  - [ ] stopAtLongBreak
- [ ] Implement `TimerEngine` transitions:
  - [ ] Focus -> Short Break
  - [ ] Focus -> Long Break (every 4th focus)
  - [ ] Break -> Focus
  - [ ] Manual skip and reset
- [ ] Implement `endDate`-based remaining time calculation.
- [ ] Add unit tests for transition correctness.
- [ ] Add unit tests for boundary stop behavior.

## M2. Main Timer UI
- [ ] Build main timer screen with:
  - [ ] Session label
  - [ ] Remaining time
  - [ ] Progress ring/bar
  - [ ] Start/Pause/Resume/Reset/Skip buttons
- [ ] Add per-boundary stop control UI:
  - [ ] "Stop at next boundary"
  - [ ] "Stop at long break"
- [ ] Apply native component styles:
  - [ ] Primary action as `.borderedProminent`
  - [ ] Secondary actions as `.bordered`
  - [ ] Progress visualization with lightweight animation
- [ ] Verify iOS/macOS interaction parity.

## M3. Notification Flow
- [ ] Request notification permission on first relevant action.
- [ ] Schedule/cancel local notifications based on current `endDate`.
- [ ] Apply notification setting:
  - [ ] Sound ON (default)
  - [ ] Silent mode
- [ ] Validate behavior on app background/restore.

## M4. Settings
- [ ] Add settings screen for:
  - [ ] Focus/Short/Long durations
  - [ ] Long break frequency
  - [ ] Auto-start toggle
  - [ ] Boundary stop policy controls
  - [ ] Notification sound toggle
- [ ] Persist settings and apply immediately to next cycle.

## M5. History
- [ ] Define `SessionRecord` model (type, start/end, duration, completed/skipped).
- [ ] Store record when each session ends.
- [ ] Create history list screen with basic filters (Focus/Break/All).
- [ ] Match history UI to native patterns (`List` + segmented filter picker).

## M6. Polish and Quality
- [ ] Improve accessibility labels and dynamic type behavior.
- [ ] Respect Reduce Motion / contrast settings.
- [ ] Add basic app icons + launch polish.
- [ ] Add tests for:
  - [ ] endDate restore
  - [ ] long-break cycle count
- [ ] Final validation:
  - [ ] `make lint`
  - [ ] `make test-macos`

## Phase 2 Backlog (Not in MVP)
- [ ] MenuBarExtra (macOS)
- [ ] Widget / Live Activity (iOS)
- [ ] Apple Watch companion
- [ ] Focus mode integration
