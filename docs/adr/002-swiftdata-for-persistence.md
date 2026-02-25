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
