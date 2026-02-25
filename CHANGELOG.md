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
- macOS NavigationSplitView and iOS NavigationStack
- SwiftData persistence (SessionRecord, UserTimerPreferences)
- Unit tests for timer state transitions
- CI pipeline (SwiftLint + tests)
