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
