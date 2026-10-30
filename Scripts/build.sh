#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG="${1:-Debug}"
DERIVED="${DEVHUB_DERIVED_DATA:-$ROOT/DerivedData}"

if [ "${SKIP_LAYER_CHECK:-0}" != "1" ]; then
    "$ROOT/Scripts/check-layers.sh"
fi
"$ROOT/Scripts/check-anonymous.sh"

xcodebuild \
    -project "$ROOT/DevHub.xcodeproj" \
    -scheme DevHub \
    -configuration "$CONFIG" \
    -destination "platform=macOS,arch=$(uname -m)" \
    -derivedDataPath "$DERIVED" \
    -quiet \
    build 2>&1 | { grep -v -E 'IDERunDestination: Supported platforms|^$' || true; }

echo "$DERIVED/Build/Products/$CONFIG/DevHub.app"
