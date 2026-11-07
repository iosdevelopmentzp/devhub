#!/bin/zsh
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/Scripts/update-status.sh"
DIR="$DEVHUB_SUPPORT_DIR/update"
LOCK="$DIR/update.lock"
mkdir -p "$DIR"

if [[ -f "$LOCK" ]] && kill -0 "$(cat "$LOCK" 2>/dev/null)" 2>/dev/null; then
    echo "An update is already running (pid $(cat "$LOCK"))"
    exit 0
fi
echo $$ > "$LOCK"
trap 'rm -f "$LOCK"' EXIT

export UPDATE_STATUS_FILE="$DIR/status.json"
export UPDATE_STARTED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "Update started at $UPDATE_STARTED_AT from $ROOT"

update_status fetching
if ! git -C "$ROOT" fetch --quiet origin "$DEVHUB_UPDATE_BRANCH" || ! git -C "$ROOT" reset --hard --quiet "origin/$DEVHUB_UPDATE_BRANCH"; then
    update_status failed "" "Could not get the changes of origin/$DEVHUB_UPDATE_BRANCH. See the log."
    exit 1
fi
echo "Source at $(git -C "$ROOT" rev-parse --short HEAD)"

if ! "$ROOT/Scripts/install.sh"; then
    update_status failed "" "The build or the install failed. See the log."
    exit 1
fi
