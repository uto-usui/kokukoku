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
