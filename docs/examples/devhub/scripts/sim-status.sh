#!/bin/zsh
# devhub: title = Simulator status
# devhub: placements = palette
# Prints the state of the app for the identity panel and one key-value block for the simulator row.
# Replace the body with what your app stores.
set -u
DATA="$(xcrun simctl get_app_container "$DEVHUB_SIMULATOR_UDID" "$DEVHUB_BUNDLE_ID" data 2>/dev/null || true)"
if [ -z "$DATA" ]; then
    echo "not installed"
    exit 0
fi
ENVIRONMENT="$(/usr/libexec/PlistBuddy -c 'Print :environment' "$DATA/Library/Preferences/group.com.example.app.plist" 2>/dev/null || echo "default")"
DEVICE_ID="$(/usr/libexec/PlistBuddy -c 'Print :deviceID' "$DATA/Library/Preferences/group.com.example.app.plist" 2>/dev/null || true)"
BETA="$(/usr/libexec/PlistBuddy -c 'Print :betaFeatures' "$DATA/Library/Preferences/group.com.example.app.plist" 2>/dev/null || echo false)"
TAGS='[]'
if [ "$BETA" = "true" ]; then
    TAGS='[{"text": "beta", "tint": "purple", "icon": "flask", "hint": "Beta features are on"}]'
fi
echo "@devhub {\"state\": {\"identity\": \"$DEVICE_ID\", \"profile\": \"$ENVIRONMENT\", \"tags\": $TAGS}}"
echo "@devhub {\"view\": {\"keyValues\": [[\"Environment\", \"$ENVIRONMENT\"], [\"ID\", \"$DEVICE_ID\"]]}}"
