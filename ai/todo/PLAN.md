# Kokukoku Planning

## 1. Goal
- Build a native-feeling Pomodoro app for `iOS` and `macOS`.
- Ship a stable, daily-usable Phase 1 first.

## 2. Product Principles
- Standard Pomodoro by default, customization as optional settings.
- Radical simplicity over feature breadth.
- Shared core logic across iOS/macOS, platform differences only where needed.

## 3. Scope by Phase

### Phase 1 (MVP)
- Timer modes: `Focus`, `Short Break`, `Long Break`
- Default durations: `25 / 5 / 15` minutes
- Core controls: `Start`, `Pause`, `Resume`, `Reset`, `Skip`
- Auto-start default `ON`
- Per-boundary stop controls:
  - `Stop at next boundary`
  - `Stop at long break`
- Long break every `4` completed focus sessions
- Local notifications
- History screen (SwiftData records)
- iOS/macOS support

### Phase 2 (Native Extensions)
- macOS `MenuBarExtra`
- iOS Widgets / Live Activity
- Apple Watch app
- Focus mode integration

### Phase 3 (Polish & Business)
- Accessibility/motion refinement
- Store assets and copy refinement
- Monetization and paywall polish

## 4. Default Behavior and Optional Settings
- Focus duration: default `25`, adjustable
- Short break duration: default `5`, adjustable
- Long break duration: default `15`, adjustable
- Long break frequency: default `4`, adjustable
- Auto-start next session: default `ON`, toggleable
- Boundary stop behavior: optional controls for each term
- Notifications:
  - Default `Sound ON`
  - Optional `Silent`
  - Note: strict cross-platform "vibration-only" is not a primary MVP mode

## 5. UI, Styling, and Native Component Plan
- Visual direction: minimal, calm, tool-like (no decorative clutter).
- Typography:
  - System font (`SF Pro`) for UI text
  - Monospaced digits for timer (`.monospacedDigit()`)
- Color policy:
  - Use semantic colors (`primary`, `secondary`, `background`) first
  - Add minimal accent tokens for session state (`focus`, `shortBreak`, `longBreak`)
- Navigation structure:
  - iOS: `NavigationStack`
  - macOS: `NavigationSplitView` (timer + history/settings access)
- Core components:
  - Timer display: large numeric label + progress ring
  - Controls: `Button` styles (`.borderedProminent` primary, `.bordered` secondary)
  - Settings: `Form` + `Section` + `Toggle` + `Stepper` + `Picker`
  - History: `List` with filter `Picker` (segmented style)
- Motion and feedback:
  - Lightweight transitions only
  - Haptics on iOS for key boundaries (where available)
- Accessibility:
  - Dynamic Type compatibility
  - VoiceOver labels for controls and timer state
  - Respect Reduce Motion / contrast settings

## 6. Technical Architecture
- UI: SwiftUI
- Domain:
  - `TimerEngine` for transitions and cycle rules
  - `TimerState`, `SessionType`, `BoundaryStopPolicy`
- Time model:
  - `endDate`-based remaining-time computation
- Persistence:
  - SwiftData (`SessionRecord`, `UserTimerPreferences`)
- Notifications:
  - UserNotifications local scheduling/canceling

## 7. Monetization Plan (Initial Fixed Policy)
- Paid app, no subscription.
- Universal purchase (`iOS + macOS`) single SKU.
- Initial price target: `¥1,500` (about `$9.99`).

## 8. Definition of Done (Phase 1)
- Timer transitions are correct in iOS/macOS.
- Background/foreground restore remains correct via `endDate`.
- Notification behavior matches settings (Sound ON / Silent).
- History is stored and viewable.
- `make lint` and `make test-macos` pass.

## 9. Planning Artifacts
- Detailed behavior spec: `PHASE1_SPEC.md`
- Release acceptance gate: `RELEASE_CHECKLIST.md`
