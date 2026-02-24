# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

**Kokukoku** (刻々) — A native Pomodoro timer for iOS and macOS. Built with Swift 6 + SwiftUI. "Radical simplicity" is the core product philosophy: timer only, no task management, no AI features, no subscription.

## Commands

```bash
make bootstrap       # Install CLI tools (swiftformat, swiftlint, xcbeautify, xcodegen)
make doctor          # Verify dev environment is ready
make format          # Run swiftformat on app code
make lint            # Run swiftlint --strict
make build-macos     # Build for macOS
make test-macos      # Run unit tests (KokukokuTests)
make test-ui-macos   # Run UI tests (KokukokuUITests)
make ci              # lint + test-macos (run before commit/push)
make clean           # Clean build artifacts
```

Xcode project: `app/Kokukoku/Kokukoku.xcodeproj`, scheme: `Kokukoku`.

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
│   │   ├── TimerStore.swift   # @Observable store: state management, ticker loop, scene phase handling
│   │   └── TimerScreen.swift  # Main timer UI
│   ├── History/
│   │   └── HistoryScreen.swift
│   └── Settings/
│       └── SettingsScreen.swift
├── Persistence/
│   ├── SessionRecord.swift    # SwiftData @Model for completed session history
│   └── UserTimerPreferences.swift  # SwiftData @Model for user settings
└── Services/
    └── NotificationService.swift   # Local notification scheduling/cancellation
```

**Key layers:**
- **Domain** — Pure types and functions with no UI or framework dependencies. `TimerEngine` is stateless; all timer logic (transitions, remaining time, progress) is computed from inputs.
- **Features** — `TimerStore` (@Observable) owns the mutable state and drives the ticker. Screens are SwiftUI views that read from the store.
- **Persistence** — SwiftData models. `SessionRecord` stores history; `UserTimerPreferences` stores settings.
- **Services** — `NotificationService` wraps UserNotifications framework.

## Critical Design Rules

- **Time model**: Timer uses `endDate` (the wall-clock time when the session ends), NOT elapsed-second counting. Remaining time = `max(0, endDate - now)`. This is essential for correct background restoration.
- **Cross-platform**: Shared logic everywhere; use `#if os(macOS)` only for platform-specific UI (navigation paradigm, layout).
- **Session transitions**: Focus → Short/Long Break → Focus. Long break triggers every N focus completions (default 4). `BoundaryStopPolicy` controls auto-advance behavior.
- **Prefer pure SwiftUI** and SF Symbols. No third-party UI dependencies.

## Code Style

- SwiftFormat (Swift 6): 4-space indent, 120 char max width, LF line endings, explicit `self`
- SwiftLint strict mode: line length warning 140 / error 180, file length warning 500 / error 900
- Timer digits use `.monospacedDigit()`. Primary action uses `.borderedProminent`, secondary `.bordered`.

## Planning Documents

Detailed specs live in `ai/todo/`:
- `PHASE1_SPEC.md` — Authoritative MVP spec (state model, transitions, time calc, notification, history, UI rules)
- `PLAN.md` — Product principles, architecture overview, definition of done
- `TASKS.md` — Implementation task breakdown (milestones M0–M6)
- `RELEASE_CHECKLIST.md` — MVP acceptance gates
- `STRATEGY.md` — Product positioning and roadmap
