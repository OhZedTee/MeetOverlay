#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
INSTALL_DIR="${INSTALL_DIR:-$HOME/Applications}"
APP_BUNDLE="$ROOT_DIR/build/MeetOverlay.app"
TARGET_APP="$INSTALL_DIR/MeetOverlay.app"

"$ROOT_DIR/scripts/build.sh"

mkdir -p "$INSTALL_DIR"

if pgrep -x MeetOverlayApp >/dev/null 2>&1; then
  osascript -e 'tell application id "dev.ilakovac.MeetOverlay" to quit' >/dev/null 2>&1 || true
  sleep 1
fi

rm -rf "$TARGET_APP"
ditto "$APP_BUNDLE" "$TARGET_APP"

printf 'Installed %s\n' "$TARGET_APP"
open "$TARGET_APP"
