# TimerScreen Visual Cleanup

**Goal:** Simplify the timer screen by removing redundant controls, differentiating button hierarchy, and improving generative mode layout.

## Changes

### 1. Button size differentiation

Primary action (Start/Pause/Resume) uses `.controlSize(.large)` to stand out.
Reset/Skip use `.controlSize(.small)` to recede visually.

**Files:** `TimerScreen.swift`

### 2. Move boundary stop controls to Settings

Remove `boundaryStopControls` from TimerScreen entirely.
The Behavior section in SettingsScreen already has a Picker for boundary stop policy — no duplication needed.

**Files:** `TimerScreen.swift`

### 3. Remove status footer

Remove `statusFooter` (Auto-start / Notifications status text) from TimerScreen.
These are visible in Settings and add visual noise to the timer view.

**Files:** `TimerScreen.swift`

### 4. Generative mode canvas overlap

Make the canvas bleed into both the session header ("Focus") above and the remaining time below, so particles visually touch the text on both sides.

Use negative vertical padding on the generative display to close the gap created by the parent VStack spacing.

**Files:** `TimerScreen.swift`, `GenerativeTimerView.swift` (overlay position if needed)
