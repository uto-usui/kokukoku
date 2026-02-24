#!/usr/bin/env bash
set -euo pipefail

echo "==> Checking Xcode"
if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "xcodebuild was not found. Install Xcode first."
  exit 1
fi

echo "==> Checking Homebrew"
if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew was not found."
  echo "Install from https://brew.sh and re-run this script."
  exit 1
fi

BREW_PREFIX="$(brew --prefix)"
if [[ ! -w "$BREW_PREFIX" ]]; then
  echo "Homebrew prefix is not writable: $BREW_PREFIX"
  echo "Run the following command in your local terminal, then re-run this script:"
  echo "  sudo chown -R $(whoami):admin $BREW_PREFIX && sudo chmod -R u+w $BREW_PREFIX"
  exit 1
fi

FORMULAS=(
  swiftformat
  swiftlint
  xcbeautify
  xcodegen
)

echo "==> Installing formulae"
for pkg in "${FORMULAS[@]}"; do
  if brew list --formula "$pkg" >/dev/null 2>&1; then
    echo "  - $pkg (already installed)"
  else
    brew install "$pkg"
  fi
done

echo "==> Done"
echo "Run ./scripts/doctor.sh to verify the environment."
