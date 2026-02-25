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
