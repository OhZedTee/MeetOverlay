#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_BUNDLE="$ROOT_DIR/build/MeetOverlay.app"
EXECUTABLE="$ROOT_DIR/.build/release/MeetOverlayApp"

detect_codesign_identity() {
  local line identity

  while IFS= read -r line; do
    if [[ "$line" == *'"Apple Development:'* ]]; then
      identity="${line#*\"}"
      printf '%s\n' "${identity%%\"*}"
      return 0
    fi
  done < <(security find-identity -v -p codesigning 2>/dev/null)

  return 1
}

cd "$ROOT_DIR"

swift test
swift build -c release

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources"

cp "$ROOT_DIR/App/Info.plist" "$APP_BUNDLE/Contents/Info.plist"
cp "$EXECUTABLE" "$APP_BUNDLE/Contents/MacOS/MeetOverlayApp"
if [ -d "$ROOT_DIR/App/Resources" ]; then
  cp -R "$ROOT_DIR/App/Resources/." "$APP_BUNDLE/Contents/Resources/"
fi
chmod +x "$APP_BUNDLE/Contents/MacOS/MeetOverlayApp"

CODESIGN_IDENTITY="${MEETOVERLAY_CODESIGN_IDENTITY:-}"
if [[ -z "$CODESIGN_IDENTITY" ]]; then
  CODESIGN_IDENTITY="$(detect_codesign_identity || true)"
fi

if [[ -z "$CODESIGN_IDENTITY" ]]; then
  CODESIGN_IDENTITY="-"
  printf 'Signing ad-hoc. Calendar permission may be requested again after rebuilds.\n'
else
  printf 'Signing with %s\n' "$CODESIGN_IDENTITY"
fi

codesign --force --sign "$CODESIGN_IDENTITY" --entitlements "$ROOT_DIR/App/Entitlements.plist" "$APP_BUNDLE"

printf 'Built %s\n' "$APP_BUNDLE"
