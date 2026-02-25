#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ICONSET_DIR="$ROOT_DIR/app/Kokukoku/Kokukoku/Assets.xcassets/AppIcon.appiconset"
BASE_ICON="$ICONSET_DIR/icon-ios-1024.png"
DARK_ICON="$ICONSET_DIR/icon-ios-dark-1024.png"
TINTED_ICON="$ICONSET_DIR/icon-ios-tinted-1024.png"

if ! command -v magick >/dev/null 2>&1; then
  echo "magick command is required."
  exit 1
fi

mkdir -p "$ICONSET_DIR"

magick \
  -size 1024x1024 \
  xc:none \
  -fill "#1E5EEA" \
  -draw "roundrectangle 24,24 1000,1000 220,220" \
  -fill "#3CB9FF" \
  -draw "circle 512,512 512,250" \
  -fill "#1E5EEA" \
  -draw "circle 512,512 512,310" \
  -stroke "#F4FAFF" \
  -strokewidth 40 \
  -fill none \
  -draw "circle 512,512 512,250" \
  -stroke "#F4FAFF" \
  -strokewidth 44 \
  -draw "line 512,512 512,354" \
  -stroke "#F4FAFF" \
  -strokewidth 30 \
  -draw "line 512,512 662,512" \
  "$BASE_ICON"

magick "$BASE_ICON" \
  -modulate 76,90,100 \
  "$DARK_ICON"

magick \
  -size 1024x1024 \
  xc:none \
  -stroke "#101010" \
  -strokewidth 72 \
  -fill none \
  -draw "circle 512,512 512,250" \
  -stroke "#101010" \
  -strokewidth 76 \
  -draw "line 512,512 512,354" \
  -stroke "#101010" \
  -strokewidth 50 \
  -draw "line 512,512 662,512" \
  "$TINTED_ICON"

generate_png() {
  local size="$1"
  local output="$2"
  sips -z "$size" "$size" "$BASE_ICON" --out "$ICONSET_DIR/$output" >/dev/null
}

generate_png 16 "icon-mac-16.png"
generate_png 32 "icon-mac-16@2x.png"
generate_png 32 "icon-mac-32.png"
generate_png 64 "icon-mac-32@2x.png"
generate_png 128 "icon-mac-128.png"
generate_png 256 "icon-mac-128@2x.png"
generate_png 256 "icon-mac-256.png"
generate_png 512 "icon-mac-256@2x.png"
generate_png 512 "icon-mac-512.png"
generate_png 1024 "icon-mac-512@2x.png"

echo "Generated AppIcon assets in $ICONSET_DIR"
