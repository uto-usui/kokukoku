# macOS Compact Window Design

**Goal:** Shrink the macOS main window from a 900×600 sidebar layout to a phone-sized compact window that matches Kokukoku's nature as a small, focused Pomodoro timer.

## Problem

The current macOS layout uses `NavigationSplitView` with a sidebar (Timer / History / Settings) and a minimum size of 900×600. This is far too large for a Pomodoro timer — it occupies significant screen real estate and conflicts with the product philosophy of being unobtrusive.

## Approach: Unified Single-Column Layout

Replace the macOS `NavigationSplitView` with `NavigationStack` + sheet pattern. The macOS window becomes a single-column timer view with History and Settings accessible via sheets from the `...` menu — matching the iPhone experience visually.

**Visual parity is the requirement, not code identity.** Both platforms should present the same timer-first single-column layout with sheets for secondary screens. Platform-specific API differences are handled with `#if os()` guards where needed.

**Why this approach:**
- Eliminates ~40 lines of macOS-specific layout code (`MacSidebarItem` enum, `NavigationSplitView`, `macLayout`)
- Unifies the visual experience across platforms (timer-first, sheets for secondary screens)
- MenuBarExtra already provides quick access to controls — the main window doesn't need persistent navigation
- Matches the design language established in the Control Hierarchy Redesign

## Platform API Compatibility

The iOS layout uses several APIs that require platform-specific handling:

| API | macOS | Strategy |
|-----|-------|----------|
| `ToolbarItemPlacement.topBarTrailing` | Available (maps to window toolbar trailing) | Share |
| `.matchedTransitionSource(id:in:)` | **Unavailable** | `#if os(iOS)` guard |
| `.navigationTransition(.zoom(...))` | **Unavailable** | `#if os(iOS)` guard |
| `.toolbarBackgroundVisibility(.hidden, for:)` | Available but different placement arg | `#if os()` — `.windowToolbar` vs `.navigationBar` |
| `.navigationBarTitleDisplayMode(.inline)` | **Unavailable** (iOS only) | `#if os(iOS)` guard |
| `ToolbarItem(placement: .cancellationAction)` | Available | Share |

**Key insight:** The zoom transition (`matchedTransitionSource` / `navigationTransition(.zoom)`) is unavailable on macOS. macOS sheets use the standard slide-down-from-titlebar animation instead. This is acceptable — macOS users expect native sheet behavior, not iOS-style zoom transitions. The visual parity goal is about layout and content, not transition animations.

## Window Configuration

| Property | Value | Rationale |
|----------|-------|-----------|
| Default size | 380 × 640 | Matches iPhone SE logical width; comfortable for timer display |
| Min size | 380 × 640 | Prevent shrinking below usable size |
| Resizable | Yes (vertical only) | Allow stretching for Settings sheet content |
| Title bar | Standard | Keep native title bar for window management (drag, close, minimize) |
| Fullscreen | System default | Accept macOS default; users are unlikely to fullscreen a 380pt timer |
| Multiple windows | Prevented | Single window enforced via `Window` scene instead of `WindowGroup` |

### Why `Window` instead of `WindowGroup`

`WindowGroup` allows macOS users to create multiple windows (⌘N). A Pomodoro timer should only have one main window — multiple windows sharing the same `TimerStore` would be confusing. `Window` enforces single-instance semantics and disables "New Window."

### ⌘, (Settings) Integration

macOS users expect `⌘,` to open Settings. Add a `Settings` scene:

```swift
#if os(macOS)
Settings {
    SettingsScreen(store: self.store)
        .modelContainer(self.sharedModelContainer)
}
#endif
```

This provides the standard macOS Settings path alongside the `...` menu.

## Layout Changes

### Before (macOS)

```
┌─────────────────────────────────────────────┐
│  ┌──────────┐  ┌──────────────────────────┐ │
│  │ Timer    │  │                          │ │
│  │ History  │  │      Timer Screen        │ │
│  │ Settings │  │                          │ │
│  │          │  │                          │ │
│  └──────────┘  └──────────────────────────┘ │
│                    900 × 600                │
└─────────────────────────────────────────────┘
```

### After (macOS)

```
┌──────────────┐
│   Kokukoku   │
│              │
│    25:00     │
│  Cycle: 0/4  │
│              │
│   [ Start ]  │
│              │
│          ... │
└──────────────┘
   380 × 640
```

## Code Changes

### 1. Delete `MacSidebarItem` enum

The `MacSidebarItem` enum in `ContentView.swift` (lines 4–34) is only used by the sidebar layout. Delete entirely.

Note: The localized strings "Timer", "History", "Settings" in `Localizable.xcstrings` should be kept — "History" and "Settings" are still used by the `...` menu and sheet titles.

### 2. Restructure `ContentView.body`

Replace the `#if os(macOS)` macLayout / `#else` iosLayout split with a shared `NavigationStack` structure. Platform differences are isolated to small `#if os()` blocks for specific modifiers.

```swift
struct ContentView: View {
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    @State private var showHistory = false
    @State private var showSettings = false
    @Bindable var store: TimerStore

    // Zoom transition namespace — iOS only, but declared on both platforms
    // to keep the @Namespace in scope for conditional usage.
    @Namespace private var sheetTransition
    @State private var hasDismissedLaunchOverlay = false

    var body: some View {
        NavigationStack {
            TimerScreen(store: self.store)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        self.ellipsisMenu
                    }
                }
                .sheet(isPresented: self.$showHistory) {
                    self.historySheet
                }
                .sheet(isPresented: self.$showSettings) {
                    self.settingsSheet
                }
                #if os(macOS)
                .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
                #else
                .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
                #endif
        }
        .overlay { /* launch overlay — unchanged */ }
        .task { self.store.bind(modelContext: self.modelContext) }
        .onChange(of: self.scenePhase) { _, newPhase in
            self.store.handleScenePhaseChange(newPhase)
        }
    }

    private var ellipsisMenu: some View {
        Menu {
            Toggle(
                isOn: Binding(
                    get: { self.store.config.ambientNoiseEnabled },
                    set: { self.store.updateAmbientNoiseEnabled($0) }
                )
            ) {
                Label("Sound", systemImage: "speaker.wave.2")
            }
            Button { self.showHistory = true } label: {
                Label("History", systemImage: "clock.arrow.circlepath")
            }
            Button { self.showSettings = true } label: {
                Label("Settings\u{2026}", systemImage: "gearshape")
            }
        } label: {
            Image(systemName: "ellipsis")
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
        #if os(iOS)
        .matchedTransitionSource(id: "systemMenu", in: self.sheetTransition)
        #endif
        .accessibilityLabel("Menu")
        .accessibilityIdentifier("nav.system")
    }

    private var historySheet: some View {
        NavigationStack {
            HistoryScreen()
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("", systemImage: "xmark") {
                            self.showHistory = false
                        }
                    }
                }
        }
        #if os(iOS)
        .navigationTransition(
            .zoom(sourceID: "systemMenu", in: self.sheetTransition)
        )
        #endif
    }

    private var settingsSheet: some View {
        NavigationStack {
            SettingsScreen(store: self.store)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("", systemImage: "xmark") {
                            self.showSettings = false
                        }
                    }
                }
        }
        #if os(iOS)
        .navigationTransition(
            .zoom(sourceID: "systemMenu", in: self.sheetTransition)
        )
        #endif
    }
}
```

**Platform-specific blocks (3 total):**
1. `.toolbarBackgroundVisibility` — different bar type (`.windowToolbar` vs `.navigationBar`)
2. `.matchedTransitionSource` — iOS-only zoom transition source
3. `.navigationTransition(.zoom)` on sheets — iOS-only zoom effect

macOS sheets use the standard macOS sheet animation (slide from titlebar), which is the expected native behavior.

### 3. Update `KokukokuApp.swift`

```swift
var body: some Scene {
    #if os(macOS)
    Window("Kokukoku", id: "main") {
        ContentView(store: self.store)
    }
    .modelContainer(self.sharedModelContainer)
    .defaultSize(width: 380, height: 640)
    .windowResizability(.contentMinSize)

    MenuBarExtra { /* unchanged */ } label: { /* unchanged */ }
        .menuBarExtraStyle(.window)
        .modelContainer(self.sharedModelContainer)

    Settings {
        SettingsScreen(store: self.store)
            .modelContainer(self.sharedModelContainer)
    }
    #else
    WindowGroup {
        ContentView(store: self.store)
    }
    .modelContainer(self.sharedModelContainer)
    #endif
}
```

**Changes from current code:**
- `WindowGroup(id: "main")` → `Window("Kokukoku", id: "main")` (single instance)
- Add `.defaultSize(width: 380, height: 640)`
- Add `.windowResizability(.contentMinSize)` (window can grow but not shrink below content size)
- Add `Settings` scene for ⌘,

### 4. MenuBarExtra remains unchanged

The MenuBarExtra (280pt wide popover) already works well as a compact quick-access panel. Its `openWindow(id: "main")` call works with both `Window` and `WindowGroup`.

### 5. Update `CLAUDE.md`

Update Architecture section: change `ContentView.swift` description from "Platform-conditional navigation (NavigationStack iOS / NavigationSplitView macOS)" to "Unified NavigationStack with sheet-based secondary screens".

### 6. Cleanup: Remove "Timer" from `Localizable.xcstrings`

The string `"Timer"` in the app's `Localizable.xcstrings` was only used by `MacSidebarItem.timer.title`. After deleting the enum, this translation is unused. Remove it to keep the string catalog clean.

## File Changes Summary

| File | Change |
|------|--------|
| `ContentView.swift` | Delete `MacSidebarItem` enum + `macLayout` + `selectedSidebarItem`. Restructure body with shared `NavigationStack` and 3 small `#if os()` blocks for platform-specific modifiers. |
| `KokukokuApp.swift` | macOS: `Window` instead of `WindowGroup`, add `.defaultSize()`, `.windowResizability()`, add `Settings` scene. iOS: unchanged `WindowGroup`. |
| `CLAUDE.md` | Update Architecture section description for `ContentView.swift`. |
| `Localizable.xcstrings` | Remove unused "Timer" / "タイマー" entry. |

## macOS-Specific Behavior

### Dock click / reopen

When the user clicks the Dock icon with the window closed, macOS automatically reopens it for `Window` scenes. No custom handler needed.

### Fullscreen

`Window` with `.windowResizability(.contentMinSize)` still shows the green fullscreen button. For initial release, accept the system default. Users are unlikely to fullscreen a 380pt timer.

### Menu bar behavior

With `Window`, the "New Window" menu item (⌘N) is automatically disabled. The "File" menu may need hiding via `.commands { CommandGroup(replacing: .newItem) {} }` if it appears empty.

### Sheet animation

macOS sheets use the standard slide-from-titlebar animation (no zoom transition). This is the expected native macOS behavior and requires no special handling.

## Testing

- Build and launch on macOS: verify window appears at ~380×640
- Verify window cannot shrink below 380×640
- Verify `...` menu opens History and Settings as sheets
- Verify ⌘, opens Settings in the standard macOS Settings window
- Verify MenuBarExtra "Open Kokukoku" still works
- Verify Dock click reopens the window after closing
- Verify ⌘N does NOT create a second window
- Verify iOS layout is unchanged (sheets still use zoom transition)
- Run `make ci` to confirm no regressions
