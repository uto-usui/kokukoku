# Documentation Improvement Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add CHANGELOG, ADRs, and API documentation (`///` comments) to the Kokukoku codebase.

**Architecture:** Three independent deliverables — CHANGELOG.md at root, ADRs in docs/adr/, and `///` comments in Domain/ and Services/. No structural changes to existing code.

**Tech Stack:** Swift Documentation Markup, Keep a Changelog format, Nygard ADR format.

---

### Task 1: Create CHANGELOG.md

**Files:**
- Create: `CHANGELOG.md`

**Step 1: Write CHANGELOG.md**

```markdown
# Changelog

All notable changes to Kokukoku will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]

### Added
- XcodeBuildMCP integration for structured build/test workflow
- SwiftFormat auto-apply hook on file edit
- Claude Code onboarding guide (CLAUDE.md)

### Changed
- Skip now advances cycle count; Reset clears cycle to initial state
- Paused state preserved when skipping sessions

### Fixed
- Timer display now refreshes every second while running

## [0.1.0] - 2026-02-20

### Added
- Core Pomodoro timer (Focus 25m / Short Break 5m / Long Break 15m)
- Session transitions with configurable long break frequency
- Boundary stop policies (none, stopAtNextBoundary, stopAtLongBreak)
- Auto-start toggle
- Settings screen (durations, frequency, auto-start, boundary policy, notification sound)
- Session history with All/Focus/Breaks filter
- Local notifications with sound on/off toggle
- macOS NavigationSplitView + iOS NavigationStack
- SwiftData persistence (SessionRecord, UserTimerPreferences)
- Unit tests for timer state transitions
- CI pipeline (SwiftLint + tests)
```

**Step 2: Run lint to verify**

Run: `make lint`
Expected: PASS (CHANGELOG.md is not a Swift file, lint should not be affected)

**Step 3: Commit**

```bash
git add CHANGELOG.md
git commit -m "docs: add CHANGELOG.md with project history"
```

---

### Task 2: Create ADR 001 — endDate-based time model

**Files:**
- Create: `docs/adr/001-enddate-based-time-model.md`

**Step 1: Write ADR**

```markdown
# ADR 001: endDate-based time model

**Status:** Accepted
**Date:** 2026-02-20

## Context

A Pomodoro timer needs to track remaining time. Two common approaches:

1. **Elapsed counting** — store `startedAt` and `elapsedSeconds`, increment a counter every tick.
2. **endDate** — store the wall-clock time when the session will end, compute remaining = `max(0, endDate - now)`.

iOS/macOS apps are regularly suspended, backgrounded, and restored. An elapsed counter requires bookkeeping to reconcile time gaps. An endDate is naturally correct after restoration — just subtract `now`.

## Decision

Use `endDate` as the source of truth for remaining time. `TimerSnapshot.endDate` stores the target wall-clock time. `TimerEngine.remainingSeconds()` computes `max(0, Int(ceil(endDate - now)))`.

When paused, store `pausedRemainingSec` as a frozen snapshot. On resume, recompute `endDate = now + pausedRemainingSec`.

## Consequences

- Background restoration is trivial — no accumulated drift or reconciliation needed.
- If `endDate` is in the past on restore, the session is complete — trigger transition.
- Timer display must re-read `Date()` every tick rather than decrementing a stored value.
- System clock changes (NTP sync, user adjustment) affect remaining time. Acceptable for a Pomodoro timer.
```

**Step 2: Commit**

```bash
git add docs/adr/001-enddate-based-time-model.md
git commit -m "docs: add ADR 001 endDate-based time model"
```

---

### Task 3: Create ADR 002 — SwiftData for persistence

**Files:**
- Create: `docs/adr/002-swiftdata-for-persistence.md`

**Step 1: Write ADR**

```markdown
# ADR 002: SwiftData for persistence

**Status:** Accepted
**Date:** 2026-02-20

## Context

Kokukoku needs to persist two kinds of data: user preferences (durations, toggles) and session history (completed/skipped records). Options considered:

1. **UserDefaults** — simple key-value. Fine for preferences, unsuitable for queryable history.
2. **Core Data** — mature, powerful. Heavy boilerplate for a simple schema.
3. **SwiftData** — Apple's modern persistence framework. Declarative `@Model`, integrates with SwiftUI via `@Query`.

## Decision

Use SwiftData for both preferences (`UserTimerPreferences`) and history (`SessionRecord`). Store raw enum values as Strings for Codable compatibility (`sessionTypeRaw`, `boundaryStopPolicyRaw`) with computed property wrappers.

## Consequences

- Requires iOS 17+ / macOS 14+. Acceptable — Kokukoku targets current OS.
- `@Model` classes use reference semantics. Keep them in the Persistence layer, pass value types to Domain.
- Schema migration is handled declaratively via `VersionedSchema` if the model evolves.
- No third-party dependencies for persistence.
```

**Step 2: Commit**

```bash
git add docs/adr/002-swiftdata-for-persistence.md
git commit -m "docs: add ADR 002 SwiftData for persistence"
```

---

### Task 4: Create ADR 003 — BoundaryStopPolicy with consumption semantics

**Files:**
- Create: `docs/adr/003-boundary-stop-policy-consumption.md`

**Step 1: Write ADR**

```markdown
# ADR 003: BoundaryStopPolicy with consumption semantics

**Status:** Accepted
**Date:** 2026-02-20

## Context

Users may want the timer to auto-advance through sessions but stop at a specific boundary (e.g., "stop before my next long break"). This requires a policy that is checked at each transition and potentially consumed (reset to `.none`) after firing.

Alternatives considered:
1. A simple boolean `stopAtNextBoundary` — insufficient, cannot express "stop only at long break".
2. A tri-state enum without consumption — the policy would fire repeatedly, requiring manual user reset.

## Decision

`BoundaryStopPolicy` is a three-case enum: `.none`, `.stopAtNextBoundary`, `.stopAtLongBreak`.

`TimerEngine.shouldStopAtBoundary()` returns a tuple `(shouldStop: Bool, consumePolicy: Bool)`. When `consumePolicy` is true, the caller resets the policy to `.none` after stopping. This makes one-shot policies like "stop at the next boundary" self-clearing.

Skip bypasses policy — it respects only `autoStart`. This prevents skipping from accidentally consuming the user's boundary stop intent.

## Consequences

- The tuple return requires the caller (TimerStore) to handle both values. Slightly complex but explicit.
- Policy is consumed only when it actually fires, not when checked.
- Adding new policies (e.g., "stop after N focus sessions") requires adding enum cases and updating `shouldStopAtBoundary`.
```

**Step 2: Commit**

```bash
git add docs/adr/003-boundary-stop-policy-consumption.md
git commit -m "docs: add ADR 003 BoundaryStopPolicy consumption semantics"
```

---

### Task 5: Create ADR 004 — TimerEngine as pure stateless functions

**Files:**
- Create: `docs/adr/004-timer-engine-pure-functions.md`

**Step 1: Write ADR**

```markdown
# ADR 004: TimerEngine as pure stateless functions

**Status:** Accepted
**Date:** 2026-02-20

## Context

Timer logic (transitions, remaining time, progress, boundary decisions) could live as methods on `TimerStore` or as a separate unit.

1. **Methods on TimerStore** — convenient access to state, but couples logic to the observable store. Hard to unit test without constructing the full store.
2. **Separate pure functions** — all inputs explicit, all outputs returned. Testable with simple value-in / value-out assertions.

## Decision

`TimerEngine` is a caseless `enum` (no instances) with `static` functions. Every function takes its inputs as parameters and returns a result. It has no stored state, no side effects, and no dependency on `TimerStore`.

`TimerStore` calls `TimerEngine` functions, passing snapshot values, and applies the results to its mutable state.

## Consequences

- Unit tests for timer logic require no mocking or store setup — just call the function.
- `TimerStore` is responsible for orchestrating calls and applying side effects (notifications, persistence).
- If logic grows complex, `TimerEngine` can be split into multiple enums without touching `TimerStore`.
```

**Step 2: Commit**

```bash
git add docs/adr/004-timer-engine-pure-functions.md
git commit -m "docs: add ADR 004 TimerEngine as pure stateless functions"
```

---

### Task 6: Add `///` documentation to TimerTypes.swift

**Files:**
- Modify: `app/Kokukoku/Kokukoku/Domain/TimerTypes.swift`

**Step 1: Add doc comments to all public types**

Add `///` comments to: `TimerState`, `SessionType`, `BoundaryStopPolicy`, `TimerConfig`, `TimerSnapshot`. Document enum cases inline with `///`. Document struct properties. Document `static let default` and `static let initial`.

Key points to document:
- `TimerState` — the three lifecycle states of a timer session
- `SessionType` — the three Pomodoro session kinds, with `title` and `symbolName` for display
- `BoundaryStopPolicy` — auto-advance control; consumed after firing (see ADR 003)
- `TimerConfig` — user-configurable durations and toggles; `default` matches standard Pomodoro (25/5/15)
- `TimerSnapshot` — current mutable state; `endDate` is the wall-clock deadline (see ADR 001); `pausedRemainingSec` freezes remaining time during pause

**Step 2: Run lint**

Run: `make lint`
Expected: PASS

**Step 3: Commit**

```bash
git add app/Kokukoku/Kokukoku/Domain/TimerTypes.swift
git commit -m "docs: add API documentation to TimerTypes.swift"
```

---

### Task 7: Add `///` documentation to TimerEngine.swift

**Files:**
- Modify: `app/Kokukoku/Kokukoku/Domain/TimerEngine.swift`

**Step 1: Add doc comments to all static functions**

Document each function with Summary + Parameters + Returns:

- `duration(for:config:)` — returns the configured duration in seconds for a session type
- `remainingSeconds(...)` — computes remaining time from endDate or paused snapshot; uses `ceil` to avoid showing 0 prematurely
- `progress(durationSec:remainingSec:)` — returns 0.0...1.0 progress ratio; returns 1.0 if duration is 0
- `nextSessionType(current:completedFocusCount:config:)` — determines the next session after completion; long break triggers when focus count is divisible by frequency
- `shouldStopAtBoundary(...)` — decides whether to stop auto-advance and whether to consume the policy; skip bypasses policy

**Step 2: Run lint**

Run: `make lint`
Expected: PASS

**Step 3: Commit**

```bash
git add app/Kokukoku/Kokukoku/Domain/TimerEngine.swift
git commit -m "docs: add API documentation to TimerEngine.swift"
```

---

### Task 8: Add `///` documentation to Service protocols

**Files:**
- Modify: `app/Kokukoku/Kokukoku/Services/NotificationService.swift`
- Modify: `app/Kokukoku/Kokukoku/Services/FocusModeService.swift`

**Step 1: Add doc comments to NotificationService.swift**

Document:
- `NotificationAuthorizationState` — three-state enum for notification permission status
- `NotificationServicing` protocol — contract for notification management
- Each protocol method: `refreshAuthorizationState`, `requestAuthorizationIfNeeded`, `scheduleSessionEndNotification`, `cancelSessionEndNotification`

**Step 2: Add doc comments to FocusModeService.swift**

Document:
- `FocusModeAuthorizationState` — five-state enum for Focus mode access
- `FocusModeStatus` — combines authorization state with current focus status
- `FocusModeServicing` protocol — contract for Focus mode integration
- Each protocol method: `refreshStatus`, `requestAuthorizationIfNeeded`

**Step 3: Run lint**

Run: `make lint`
Expected: PASS

**Step 4: Commit**

```bash
git add app/Kokukoku/Kokukoku/Services/NotificationService.swift app/Kokukoku/Kokukoku/Services/FocusModeService.swift
git commit -m "docs: add API documentation to Service protocols"
```

---

### Task 9: Final verification

**Step 1: Run full CI check**

Run: `make ci`
Expected: lint PASS, tests PASS (21 tests)

**Step 2: Verify documentation coverage**

Check that all public types in Domain/ and all protocol methods in Services/ have `///` comments.

**Step 3: Commit design doc**

```bash
git add docs/
git commit -m "docs: add design doc and implementation plan for documentation improvement"
```
