# Control Hierarchy Redesign

**Goal:** Reorganize all interactive controls into a clear 3-tier hierarchy tied to timer state. Reduce visual noise so the time display remains the undisputed protagonist.

## Design

### 1. Three Control Tiers

| Tier | Controls | Visibility Rule |
|------|----------|-----------------|
| **Primary** | Start / Pause | Always visible |
| **Contextual** | Reset / Skip | Paused only |
| **System** | Settings, History, Sound | State-dependent (see below) |

### 2. State-Based Visibility

| State | Primary | Contextual (Reset/Skip) | System (toolbar) |
|-------|---------|------------------------|------------------|
| **Idle** | Start | Hidden | Visible (single `...` icon) |
| **Running** | Pause | Hidden | Hidden; tap timer area to reveal for 2s |
| **Paused** | Resume | Visible | Visible |

### 3. Toolbar Consolidation

**Current:** Two icons in top-right (History clock, Settings gear).

**New:** Single `ellipsis.circle` icon → presents a sheet containing:
- History
- Settings
- Sound toggle (ambient noise on/off)

This reduces the visual footprint from 2 icons to 1, keeping the time display as the focal point.

## Files Affected

- `ContentView.swift` — Replace 2 toolbar NavigationLinks with single `...` button + sheet
- `TimerScreen.swift` — Wire state-based visibility for Contextual and System tiers
- New: `SystemSheet.swift` — Sheet view with History/Settings/Sound navigation

## Implementation Tasks

### Task 1: Create SystemSheet view
- New file: `Features/Timer/SystemSheet.swift`
- NavigationStack inside a sheet with List rows:
  - "History" → `HistoryScreen()`
  - "Settings" → `SettingsScreen(store:)`
  - "Sound" → Toggle for `store.config.ambientNoiseEnabled`
- Accept `TimerStore` binding and `ModelContext` via environment

### Task 2: Replace toolbar icons with single `...` button
- In `ContentView.swift` iOS layout:
  - Remove the 2 `NavigationLink` toolbar items
  - Add single `Button` with `Image(systemName: "ellipsis.circle")`
  - `@State private var showSystemSheet = false`
  - `.sheet(isPresented: $showSystemSheet) { SystemSheet(...) }`
- Wire `showSystemSheet` state

### Task 3: State-based toolbar visibility
- In `ContentView.swift`, make the `...` toolbar button conditional on timer state:
  - Idle: visible
  - Running: hidden (revealed on tap for 2s via TimerScreen's tap gesture)
  - Paused: visible
- Pass `store.timerState` into the toolbar visibility logic
- Reuse `secondaryControlsReveal` pattern from TimerScreen for running-state reveal

### Task 4: Contextual controls (Reset/Skip) state logic
- In `TimerScreen.swift` standard mode:
  - Reset/Skip visible only when `timerState == .paused` (always visible, no tap needed)
  - Remove the `secondaryControlsReveal` tap-to-show pattern for paused state
  - When running: Reset/Skip hidden (tap to reveal for 2s, same as System)
  - When idle: Reset/Skip hidden

### Task 5: Running-state tap-to-reveal unification
- When timer is running and user taps the screen:
  - Both System toolbar (`...`) and Contextual (Reset/Skip) fade in
  - Auto-hide after 2s
- TimerScreen communicates reveal state to ContentView (e.g., via `store` property or Binding)
- Ensure tap doesn't interfere with Primary button (Start/Pause)

### Task 6: Verify and build
- macOS build (spike)
- iOS simulator build + visual verification for all 3 states (idle, running, paused)
- Verify sheet navigation works (History, Settings, Sound toggle)
