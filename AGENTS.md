# Project Agent Notes

See [README.md](README.md) for project overview, platforms, setup, and commands.

## Engineering Rules

- Keep shared logic cross-platform; branch only for platform-specific UI APIs.
- Model timer state by storing `endDate`, not by counting elapsed seconds in memory.
- Keep `TimerStore` as the single source of truth for timer/session transitions.
- Sync watch state from iPhone via `WCSession.updateApplicationContext`; send watch commands back to iPhone (`primaryAction`, `reset`, `skip`).
- Prefer pure SwiftUI and system symbols for native look and long-term maintenance.
- Keep files small and composable.

## Definition of Done

- Builds on latest stable Xcode.
- Works on iOS Simulator and macOS.
- watchOS companion target builds as part of `Kokukoku` iOS simulator build.
- Notification behavior validated for background/foreground.
- Basic tests exist for timer state transitions.
- `make lint` and `make test-macos` pass.
