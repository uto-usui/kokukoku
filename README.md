# Kokukoku (Apple Native Pomodoro)

`Kokukoku` is a native Pomodoro app built with `Swift + SwiftUI`.

Current implementation status:
- Core app (`iOS + macOS`) complete
- `MenuBarExtra` (macOS) implemented
- `Widget / Live Activity` (iOS) implemented
- `Apple Watch companion` implemented (`WatchConnectivity`)
- `Focus mode integration` implemented
- `Japanese localization` (String Catalogs across all targets)

## Quick Start

```bash
cd /Users/usui.y/work/uto/pomodoro-timer
make bootstrap
make doctor
make lint
make test-macos
```

If `bootstrap` fails with `Homebrew prefix is not writable`, run:

```bash
sudo chown -R usui.y:admin /opt/homebrew && sudo chmod -R u+w /opt/homebrew
```

## What `bootstrap` installs

- `swiftformat`
- `swiftlint`
- `xcbeautify`
- `xcodegen`

## Current Project

- App name: `Kokukoku`
- Xcode project: `/Users/usui.y/work/uto/pomodoro-timer/app/Kokukoku/Kokukoku.xcodeproj`
- Main scheme: `Kokukoku`
- Additional schemes: `KokukokuWidget`, `KokukokuWatch`

## Make targets

```bash
make help
```

Main commands:

- `make format`
- `make lint`
- `make build-macos`
- `make test-macos` (unit tests)
- `make test-ui-macos` (UI tests)
- `make ci`

Useful direct commands:

```bash
xcodebuild -project app/Kokukoku/Kokukoku.xcodeproj -scheme Kokukoku -configuration Debug -destination 'generic/platform=iOS Simulator' build | xcbeautify
```

## LLM-first workflow (recommended)

```bash
cursor /Users/usui.y/work/uto/pomodoro-timer
```

- Use Cursor for implementation.
- Use Xcode for signing, simulator, profiling, archive, TestFlight.
- Run `make doctor` before starting work.
- Run `make ci` before commit/push.

## Documentation

- `CLAUDE.md` — Architecture, code style, build strategy, document index
- `ai/todo/` — MVP spec, implementation tasks, release checklist, product strategy
- `docs/store/` — App Store marketing strategy (original ¥1,500 buy-once model)
- `docs/store/pivot/` — Pivot strategy (free → ¥300/$2.99, LP, note.com/Patreon)
- `docs/appstore/` — Privacy policy, review notes, technical metadata, compliance
- `docs/adr/` — Architecture Decision Records
- `docs/plans/` — Implementation plans

## Watch Companion Verification

- Launch `Kokukoku` on an iPhone + Apple Watch paired simulator.
- Confirm iPhone `Start/Pause/Resume` updates Watch state and remaining time.
- Confirm Watch `Start/Pause/Reset/Skip` updates iPhone timer state.
