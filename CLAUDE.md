# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

See [README.md](README.md) for project overview, platforms, setup, and commands.

To run a single test via xcodebuild:
```bash
xcodebuild -project app/Kokukoku/Kokukoku.xcodeproj -scheme Kokukoku -configuration Debug -destination "platform=macOS" -only-testing:"KokukokuTests/TestClassName/testMethodName" test | xcbeautify
```

## Architecture

```
app/Kokukoku/Kokukoku/
├── KokukokuApp.swift          # Entry point, SwiftData ModelContainer setup
├── ContentView.swift          # Platform-conditional navigation (NavigationStack iOS / NavigationSplitView macOS)
├── Domain/
│   ├── TimerTypes.swift       # Value types: TimerState, SessionType, BoundaryStopPolicy, TimerConfig, TimerSnapshot
│   └── TimerEngine.swift      # Pure stateless functions for transitions, time calc, progress
├── Features/
│   ├── Timer/
│   │   ├── TimerStore.swift           # @Observable store: state management, ticker loop, scene phase handling
│   │   ├── TimerStoreTypes.swift      # Internal value types (SessionRecordPayload, BoundaryTransitionContext)
│   │   ├── TimerStorePersistence.swift # SwiftData binding and preference sync
│   │   ├── TimerStoreWatchSync.swift  # WatchConnectivity state sync
│   │   └── TimerScreen.swift          # Main timer UI
│   ├── MenuBar/
│   │   └── MenuBarTimerView.swift     # macOS MenuBarExtra timer view
│   ├── History/
│   │   └── HistoryScreen.swift
│   └── Settings/
│       └── SettingsScreen.swift
├── Shared/
│   └── LiveActivity/
│       └── KokukokuActivityAttributes.swift  # ActivityKit attributes shared with widget extension
├── Persistence/
│   ├── SessionRecord.swift    # SwiftData @Model for completed session history
│   └── UserTimerPreferences.swift  # SwiftData @Model for user settings
└── Services/
    ├── NotificationService.swift       # Local notification scheduling/cancellation
    ├── FocusModeService.swift          # Focus mode (DnD) integration via INFocusStatusCenter
    ├── WatchConnectivityService.swift  # iPhone <-> Watch state sync via WCSession
    └── LiveActivityService.swift       # Live Activity lifecycle management
```

**Key layers:**
- **Domain** — Pure types and functions with no UI or framework dependencies. `TimerEngine` is stateless; all timer logic (transitions, remaining time, progress) is computed from inputs.
- **Features** — `TimerStore` (@Observable) owns the mutable state and drives the ticker. Split into extensions: core logic, persistence binding, watch sync. Screens are SwiftUI views that read from the store.
- **Persistence** — SwiftData models. `SessionRecord` stores history; `UserTimerPreferences` stores settings.
- **Services** — `NotificationService`, `FocusModeService`, `WatchConnectivityService`, `LiveActivityService`. Each wraps a system framework behind a protocol.

## Critical Design Rules

- **Time model**: Timer uses `endDate` (the wall-clock time when the session ends), NOT elapsed-second counting. Remaining time = `max(0, endDate - now)`. This is essential for correct background restoration.
- **Cross-platform**: Shared logic everywhere; use `#if os(macOS)` only for platform-specific UI (navigation paradigm, layout).
- **Session transitions**: Focus → Short/Long Break → Focus. Long break triggers every N focus completions (default 4). `BoundaryStopPolicy` controls auto-advance behavior.
- **Prefer pure SwiftUI** and SF Symbols. No third-party UI dependencies.

## XcodeBuildMCP

This project has XcodeBuildMCP configured as an MCP server. Prefer MCP tools over raw `xcodebuild` commands for build, test, and simulator operations — errors are returned as structured data.

**Session defaults** (set at session start):
```
projectPath: app/Kokukoku/Kokukoku.xcodeproj
scheme: Kokukoku
configuration: Debug
simulatorId: (use list_sims to find a booted iPhone simulator)
```

**Typical workflow:**
1. `session_show_defaults` → confirm project/scheme/simulator are set
2. `build_sim` → compile for iOS Simulator
3. `test_sim` with `extraArgs: ["-only-testing:KokukokuTests"]` → run unit tests
4. `test_sim` with `extraArgs: ["-only-testing:KokukokuTests/TestClassName/testMethodName"]` → run a single test

For macOS-only builds/tests, fall back to `make build-macos` / `make test-macos`.

## Code Style

- SwiftFormat (Swift 6): 4-space indent, 120 char max width, LF line endings, explicit `self`
- SwiftLint strict mode: line length warning 140 / error 180, file length warning 500 / error 900
- Timer digits use `.monospacedDigit()`. Primary action uses `.borderedProminent`, secondary `.bordered`.

## Documentation

**`///` comments — what to document:**
- Domain layer (types, engine functions): required. These define the core model and must be self-explanatory.
- Service protocols: required. Document the contract, not the implementation.
- View layer, private helpers, SwiftData models: not required. Names should be self-explanatory.

**`///` style:** Swift Documentation Markup. Summary line first, then detail only when non-obvious. Use `- Parameter`, `- Returns:` for functions with non-trivial signatures.

**ADRs (`docs/adr/`):** Record design decisions that aren't obvious from reading the code. Lightweight Nygard format (Status, Context, Decision, Consequences). Only create an ADR when the "why" matters — e.g., choosing endDate over elapsed counting, not "we used SwiftUI because it's a SwiftUI app."

**CHANGELOG.md:** [Keep a Changelog](https://keepachangelog.com/) format. Update the `[Unreleased]` section when adding features, fixes, or breaking changes. Cut a version section on release.

**No separate ARCHITECTURE.md** — this file (CLAUDE.md) serves that role.

## Build Verification Strategy

See `docs/plans/2026-02-25-build-verification-strategy.md` for full design rationale and measured build times.

**3-stage approach (cost-effective for LLM development):**

1. **Spike build** — Run `make build-macos` (~12s) after structural changes (new files, target membership, Info.plist, pbxproj edits). Catches compilation errors early without blocking development.
2. **Background iOS build** — Run `make build-ios` (~25s) in background after completing a logical unit of work. Catches cross-platform issues (WatchConnectivity, #if os() guards, widget extensions) without blocking.
3. **Full gate** — Run `make ci` (lint + test-macos + build-ios) before commit/push. This is the final quality gate.

**When to trigger each stage:**
- Stage 1: New file added, target membership changed, import added, `#if os()` block modified
- Stage 2: After completing a feature or fixing a bug (run in background while continuing)
- Stage 3: Before every commit

**Key safeguards:**
- `WatchConnectivityService` uses `assertionFailure` in Debug to crash on invalid plist payloads
- `WatchSyncPayload.build()` is a pure function with unit tests for plist type safety
- CI runs lint + macOS tests + iOS Simulator build on every PR and push to main/master

## Planning Documents

Detailed specs live in `ai/todo/`:
- `PHASE1_SPEC.md` — Authoritative MVP spec (state model, transitions, time calc, notification, history, UI rules)
- `PLAN.md` — Product principles, architecture overview, definition of done
- `TASKS.md` — Implementation task breakdown (milestones M0–M6)
- `RELEASE_CHECKLIST.md` — MVP acceptance gates
- `STRATEGY.md` — Product positioning and roadmap
