#!/usr/bin/env bash
set -euo pipefail

check_cmd() {
  local cmd="$1"
  local version_cmd="$2"

  if command -v "$cmd" >/dev/null 2>&1; then
    echo "[OK] $cmd"
    eval "$version_cmd" | head -n 1
  else
    echo "[NG] $cmd (missing)"
  fi
  echo ""
}

echo "==> OS"
sw_vers
echo ""

echo "==> Developer Tools"
if command -v xcodebuild >/dev/null 2>&1; then
  xcodebuild -version
  xcode-select -p
else
  echo "[NG] xcodebuild (missing)"
fi
echo ""

echo "==> CLI Tools"
check_cmd "brew" "brew --version"
check_cmd "swift" "swift --version"
check_cmd "swiftformat" "swiftformat --version"
check_cmd "swiftlint" "swiftlint version"
check_cmd "xcbeautify" "xcbeautify --version"
check_cmd "xcodegen" "xcodegen version"
check_cmd "gh" "gh --version"
check_cmd "cursor" "cursor --version"

echo "==> GitHub auth"
if gh auth status >/dev/null 2>&1; then
  echo "[OK] gh auth status"
else
  echo "[WARN] gh is not authenticated yet (run: gh auth login)"
fi
