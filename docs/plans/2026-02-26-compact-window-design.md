# macOS Compact Window Design

**Goal:** Shrink the macOS main window from a 900×600 sidebar layout to a phone-sized compact window that matches Kokukoku's nature as a small, focused Pomodoro timer.

## Problem

The current macOS layout uses `NavigationSplitView` with a sidebar (Timer / History / Settings) and a minimum size of 900×600. This is far too large for a Pomodoro timer — it occupies significant screen real estate and conflicts with the product philosophy of being unobtrusive.

## Approach: Unified Single-Column Layout

Replace the macOS `NavigationSplitView` with the same `NavigationStack` + sheet pattern already used on iOS. The macOS window becomes a single-column timer view with History and Settings accessible via sheets from the `...` menu — identical to the iPhone experience.

**Why this approach:**
- Eliminates ~40 lines of macOS-specific layout code (`MacSidebarItem` enum, `NavigationSplitView`, `macLayout`)
- Unifies the interaction model across platforms (timer-first, sheets for secondary screens)
- MenuBarExtra already provides quick access to controls — the main window doesn't need persistent navigation
- Matches the design language established in the Control Hierarchy Redesign

## Window Configuration

| Property | Value | Rationale |
|----------|-------|-----------|
| Default size | 380 × 640 | Matches iPhone SE logical width; comfortable for timer display |
| Min size | 380 × 640 | Prevent shrinking below usable size |
| Resizable | Yes (vertical only) | Allow stretching for Settings sheet content |
| Title bar | Standard | Keep native title bar for window management (drag, close, minimize) |
| Fullscreen | Disabled | Pomodoro timer should not go fullscreen — use `.windowStyle(.hiddenTitleBar)` is NOT used; instead disable via window delegate or accept system default |
| Multiple windows | Prevented | Single window enforced via `Window` scene instead of `WindowGroup` |

### Why `Window` instead of `WindowGroup`

`WindowGroup` allows macOS users to create multiple windows (⌘N). A Pomodoro timer should only have one main window — multiple windows sharing the same `TimerStore` would be confusing and serve no purpose. `Window` enforces single-instance semantics and disables the "New Window" menu item.

```swift
#if os(macOS)
Window("Kokukoku", id: "main") {
    ContentView(store: self.store)
}
.defaultSize(width: 380, height: 640)
.windowResizability(.contentMinSize)
#else
WindowGroup {
    ContentView(store: self.store)
}
#endif
```

Note: `Window` is macOS-only. iOS continues to use `WindowGroup`.

### ⌘, (Settings) Integration

macOS users expect `⌘,` to open Settings. Add a `Settings` scene or use `.commands` to wire ⌘, to the existing Settings sheet:

```swift
#if os(macOS)
Settings {
    SettingsScreen(store: self.store)
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

### 2. Unify `ContentView.body`

Remove the `#if os(macOS)` / `#else` split. Use the iOS layout (`NavigationStack` + sheets + `...` menu) for both platforms, with platform-specific toolbar adjustments:

```swift
struct ContentView: View {
    // ... existing @Environment properties ...
    @Namespace private var sheetTransition
    @State private var showHistory = false
    @State private var showSettings = false
    @Bindable var store: TimerStore

    var body: some View {
        NavigationStack {
            TimerScreen(store: self.store)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Toggle(isOn: /* ambientNoise binding */) {
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
                        .matchedTransitionSource(id: "systemMenu", in: self.sheetTransition)
                        .accessibilityLabel("Menu")
                        .accessibilityIdentifier("nav.system")
                    }
                }
                .sheet(isPresented: self.$showHistory) { /* HistoryScreen in NavigationStack */ }
                .sheet(isPresented: self.$showSettings) { /* SettingsScreen in NavigationStack */ }
                #if os(macOS)
                .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
                #else
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
                #endif
        }
        .overlay { /* launch overlay — unchanged */ }
        .task { self.store.bind(modelContext: self.modelContext) }
        .onChange(of: self.scenePhase) { _, newPhase in
            self.store.handleScenePhaseChange(newPhase)
        }
    }
}
```

The only `#if os()` remaining is for `.toolbarBackgroundVisibility` (different bar type per platform) and `.navigationBarTitleDisplayMode` (iOS-only API).

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

### 4. MenuBarExtra remains unchanged

The MenuBarExtra (280pt wide popover) already works well as a compact quick-access panel. Its `openWindow(id: "main")` call works with both `Window` and `WindowGroup`.

## File Changes Summary

| File | Change |
|------|--------|
| `ContentView.swift` | Delete `MacSidebarItem` enum + `macLayout` + `selectedSidebarItem`. Merge `iosLayout` into `body` with platform-specific toolbar modifiers. |
| `KokukokuApp.swift` | macOS: `Window` instead of `WindowGroup`, add `.defaultSize()`, `.windowResizability()`, add `Settings` scene. iOS: unchanged `WindowGroup`. |
| `CLAUDE.md` | Update Architecture section: remove `NavigationSplitView` reference |

## macOS-Specific Behavior

### Dock click / reopen

When the user clicks the Dock icon with the window closed, macOS automatically reopens it for `Window` scenes. No custom handler needed.

### Fullscreen

`Window` with `.windowResizability(.contentMinSize)` still shows the green fullscreen button. To disable fullscreen for this utility app, the window can be marked with `NSWindow.StyleMask` adjustments if needed — but this requires AppKit bridging. For initial release, accept the system default (fullscreen allowed but not optimized). Users are unlikely to fullscreen a 380pt timer.

### Menu bar behavior

With `Window`, the "New Window" menu item (⌘N) is automatically disabled. The "File" menu may need hiding via `.commands { CommandGroup(replacing: .newItem) {} }` if it appears empty.

## Testing

- Build and launch on macOS: verify window appears at ~380×640
- Verify window can stretch vertically but not shrink below 380×640
- Verify `...` menu opens History and Settings as sheets
- Verify ⌘, opens Settings in the standard macOS Settings window
- Verify MenuBarExtra "Open Kokukoku" still works
- Verify Dock click reopens the window after closing
- Verify ⌘N does NOT create a second window
- Verify iOS layout is unchanged (still uses `WindowGroup`)
- Run `make ci` to confirm no regressions
