# Changelog

All notable changes to Kokukoku will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]

## [0.1.0] - 2026-02-26

### Added
- Core Pomodoro timer (Focus 25m / Short Break 5m / Long Break 15m)
- Session transitions with configurable long break frequency
- Boundary stop policies (none, stopAtNextBoundary, stopAtLongBreak)
- Auto-start toggle
- Settings screen (durations, frequency, auto-start, boundary policy, notification sound)
- Session history with All/Focus/Breaks filter
- Local notifications with sound on/off toggle
- SwiftData persistence (SessionRecord, UserTimerPreferences)
- Japanese localization (String Catalogs) for App, Watch, and Widget targets
- Material surface texture (grain overlay) and vibrant typography via `.ultraThinMaterial`
- Ambient noise (pink noise) during focus sessions
- Haptic feedback on session transitions
- System Focus Mode integration (mute sounds when Focus active)
- Consolidated `...` menu in toolbar (Sound toggle, History, Settings)
- Sheet presentation for History and Settings with zoom transition
- macOS MenuBarExtra with timer status
- Apple Watch companion app
- iOS Widget and Live Activity
- Unit tests (81) and macOS UI tests (4)
- CI pipeline (SwiftLint + tests + iOS build)

### Changed
- macOS: Compact 380×640 single-column window (single instance, ⌘, for Settings)
- Timer digits: 100pt thin weight, vibrant over material background
- Primary button: glass capsule style
- Reset/Skip visible only when paused
