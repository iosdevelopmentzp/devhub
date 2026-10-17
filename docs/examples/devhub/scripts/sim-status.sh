#!/bin/zsh
# devhub: title = Simulator status
# Prints one key-value block for the simulator row. Replace the body with what your app stores.
set -u
DATA="$(xcrun simctl get_app_container "$DEVHUB_SIMULATOR_UDID" "$DEVHUB_BUNDLE_ID" data 2>/dev/null || true)"
if [ -z "$DATA" ]; then
    echo "not installed"
    exit 0
fi
ENVIRONMENT="$(/usr/libexec/PlistBuddy -c 'Print :environment' "$DATA/Library/Preferences/group.com.example.app.plist" 2>/dev/null || echo "default")"
echo "@devhub {\"view\": {\"keyValues\": [[\"Environment\", \"$ENVIRONMENT\"]]}}"
