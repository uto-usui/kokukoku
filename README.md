# Pomodoro Timer (Apple Native) Dev Environment

This workspace is prepared for building a native `iOS + macOS` Pomodoro app with `Swift + SwiftUI`.

## Quick Start

```bash
cd /Users/usui.y/work/uto/pomodoro-timer
make bootstrap
make doctor
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

## Create the app project

1. Open Xcode.
2. Create a new **Multiplatform App** project.
3. Product name example: `PomodoroTimer`.
4. Interface: `SwiftUI`, Language: `Swift`, Data storage: `SwiftData`.
5. Save it under:
   `/Users/usui.y/work/uto/pomodoro-timer/app`

## LLM-first workflow (recommended)

```bash
cursor /Users/usui.y/work/uto/pomodoro-timer
```

- Use Cursor for implementation.
- Use Xcode for signing, simulator, profiling, archive, TestFlight.
- Run `make doctor` before starting work.
