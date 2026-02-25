# Control Hierarchy Redesign

**Goal:** Reorganize all interactive controls into a clear hierarchy. Reduce visual noise so the time display remains the undisputed protagonist.

## Final Design (post-AD feedback)

### Two Control Tiers

| Tier | Controls | Visibility Rule |
|------|----------|-----------------|
| **Primary** | Start / Pause / Resume | Always visible |
| **Contextual** | Reset / Skip | Paused only (inline below primary button) |

### System Menu (`...`)

Single `ellipsis` icon in the toolbar (always visible, all states). Opens a Liquid Glass popover menu containing:

1. **Sound** — Toggle for ambient noise (`speaker.wave.2`)
2. **History** — Opens HistoryScreen as sheet (`clock.arrow.circlepath`)
3. **Settings...** — Opens SettingsScreen as sheet (`gearshape`)

Order rationale: most-used during focus first (Sound), confirmation second (History), deep config last (Settings).

### Sheet Presentation

- History and Settings open as `.sheet()` with `NavigationStack` inside
- Each sheet has a `×` button (`.cancellationAction` toolbar placement)
- `matchedTransitionSource` / `.navigationTransition(.zoom)` connects sheets to the menu source for contextual zoom transition
- `.toolbarBackgroundVisibility(.hidden, for: .navigationBar)` removes nav bar glass from the timer screen

### State-Based Visibility

| State | Primary | Contextual (Reset/Skip) | System (`...` menu) |
|-------|---------|------------------------|---------------------|
| **Idle** | Start | Hidden | Visible |
| **Running** | Pause | Hidden | Visible |
| **Paused** | Resume | Visible (fade in) | Visible |

Key decision: the `...` menu is **always visible** across all states. Original plan had running-state hide + tap-to-reveal, but AD feedback simplified this — the Liquid Glass pill provides enough visual subtlety that hiding is unnecessary.

## Files Changed

- `ContentView.swift` — Replace 2 toolbar NavigationLinks with single Menu + sheet presentations
- `TimerScreen.swift` — Remove tap-to-reveal mechanism, paused-only Reset/Skip visibility

## Design Evolution

1. **Initial plan**: 3-tier hierarchy with SystemSheet (NavigationStack in sheet), tap-to-reveal during running state
2. **AD feedback round 1**: Sheet → Menu popover (Liquid Glass), Reset/Skip in menu when paused
3. **AD feedback round 2**: Reset/Skip back to inline buttons (paused only), menu order Sound→History→Settings
4. **AD feedback round 3**: Menu always visible (remove running-state hide), `ellipsis` icon (no circle), `.toolbarBackgroundVisibility(.hidden)`
