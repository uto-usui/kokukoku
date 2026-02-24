# Pomodoro Timer (Apple Native) Dev Environment

This workspace is prepared for building a native `iOS + macOS` Pomodoro app with `Swift + SwiftUI`.

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
- Scheme: `Kokukoku`

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

## LLM-first workflow (recommended)

```bash
cursor /Users/usui.y/work/uto/pomodoro-timer
```

- Use Cursor for implementation.
- Use Xcode for signing, simulator, profiling, archive, TestFlight.
- Run `make doctor` before starting work.
- Run `make ci` before commit/push.
