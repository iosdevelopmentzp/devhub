#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TARGET="${DEVHUB_INSTALL_PATH:-/Applications/DevHub Generic.app}"
EXECUTABLE="$TARGET/Contents/MacOS/DevHub"
APP="$(DEVHUB_DERIVED_DATA="$ROOT/DerivedData/Install" "$ROOT/Scripts/build.sh" Release | tail -1)"
IDENTITY="${DEVHUB_SIGN_IDENTITY:-}"
IDENTITY_FILE="$HOME/.config/devhub/sign-identity"
if [[ -z "$IDENTITY" && -f "$IDENTITY_FILE" ]]; then
    IDENTITY="$(tr -d '[:space:]' < "$IDENTITY_FILE")"
fi

STAGED="$TARGET.new"
rm -rf "$STAGED"
ditto "$APP" "$STAGED"
if [[ -n "$IDENTITY" ]]; then
    codesign --force --sign "$IDENTITY" --preserve-metadata=identifier,entitlements "$STAGED"
fi

pkill -TERM -f "^$EXECUTABLE" 2>/dev/null || true
for _ in {1..50}; do
    pgrep -f "^$EXECUTABLE" >/dev/null || break
    sleep 0.2
done
pkill -KILL -f "^$EXECUTABLE" 2>/dev/null || true

rm -rf "$TARGET"
mv "$STAGED" "$TARGET"
open "$TARGET"
echo "Installed $TARGET (signed: ${IDENTITY:-ad-hoc})"
