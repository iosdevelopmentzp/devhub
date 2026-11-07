#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/Scripts/update-status.sh"
SOURCE="$DEVHUB_SUPPORT_DIR/source"
UPDATE_DIR="$DEVHUB_SUPPORT_DIR/update"
TARGET="${DEVHUB_INSTALL_PATH:-/Applications/DevHub Generic.app}"
EXECUTABLE="$TARGET/Contents/MacOS/DevHub"

update_status building
APP="$(DEVHUB_DERIVED_DATA="$ROOT/DerivedData/Install" "$ROOT/Scripts/build.sh" Release | tail -1)"
COMMIT="$(git -C "$ROOT" rev-parse HEAD)"
IDENTITY="${DEVHUB_SIGN_IDENTITY:-}"
IDENTITY_FILE="$HOME/.config/devhub/sign-identity"
if [[ -z "$IDENTITY" && -f "$IDENTITY_FILE" ]]; then
    IDENTITY="$(tr -d '[:space:]' < "$IDENTITY_FILE")"
fi

if [[ ! -d "$SOURCE/.git" ]]; then
    REMOTE="$(git -C "$ROOT" remote get-url origin)"
    mkdir -p "$DEVHUB_SUPPORT_DIR"
    git clone --quiet --branch "$DEVHUB_UPDATE_BRANCH" "$REMOTE" "$SOURCE"
    echo "Created the build clone $SOURCE from $REMOTE"
fi

STAGED="$TARGET.new"
rm -rf "$STAGED"
ditto "$APP" "$STAGED"
if [[ -n "$IDENTITY" ]]; then
    codesign --force --sign "$IDENTITY" --preserve-metadata=identifier,entitlements "$STAGED"
fi

update_status installing
if [[ -n "${UPDATE_STATUS_FILE:-}" ]]; then
    for _ in {1..25}; do
        pgrep -f "^$EXECUTABLE" >/dev/null || break
        sleep 0.2
    done
fi
pkill -TERM -f "^$EXECUTABLE" 2>/dev/null || true
for _ in {1..50}; do
    pgrep -f "^$EXECUTABLE" >/dev/null || break
    sleep 0.2
done
pkill -KILL -f "^$EXECUTABLE" 2>/dev/null || true

rm -rf "$TARGET"
mv "$STAGED" "$TARGET"
write_json_atomically "$UPDATE_DIR/installed.json" "{\"commit\": \"$COMMIT\", \"branch\": \"$DEVHUB_UPDATE_BRANCH\", \"source\": $(json_string "$SOURCE"), \"installedAt\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}"
update_status done "$COMMIT"
open "$TARGET"
echo "Installed $TARGET at ${COMMIT:0:7} (signed: ${IDENTITY:-ad-hoc})"
