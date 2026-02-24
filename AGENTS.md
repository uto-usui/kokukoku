# Project Agent Notes

This repository is for an Apple-native Pomodoro timer app.

## Product Scope

- Platforms: `iOS` and `macOS`
- UI: `SwiftUI`
- Language: `Swift`
- Persistence: `SwiftData`
- Notifications: `UserNotifications`
- Optional extensions: `WidgetKit`, `ActivityKit`, `MenuBarExtra`

## Engineering Rules

- Keep shared logic cross-platform; branch only for platform-specific UI APIs.
- Model timer state by storing `endDate`, not by counting elapsed seconds in memory.
- Prefer pure SwiftUI and system symbols for native look and long-term maintenance.
- Keep files small and composable.

## Commands

```bash
make bootstrap
make doctor
```

## Definition of Done

- Builds on latest stable Xcode.
- Works on both iOS Simulator and macOS.
- Notification behavior validated for background/foreground.
- Basic tests exist for timer state transitions.
