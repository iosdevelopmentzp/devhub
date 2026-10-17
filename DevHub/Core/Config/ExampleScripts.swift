import Foundation

nonisolated enum ExampleScripts {
    static let all: [ExampleFile] = [
        ExampleFile(path: "scripts/clean-derived-data.sh", isExecutable: true, content: #"""
#!/bin/zsh
set -euo pipefail
ROOT="$HOME/Library/Developer/Xcode/DerivedData"
echo "@devhub {\"progress\": \"Looking for DerivedData of $DEVHUB_CHECKOUT_PATH\"}"
REMOVED=0
for folder in "$ROOT"/*/; do
    plist="$folder/info.plist"
    [ -f "$plist" ] || continue
    workspace="$(/usr/libexec/PlistBuddy -c 'Print :WorkspacePath' "$plist" 2>/dev/null || true)"
    case "$workspace" in
        "$DEVHUB_CHECKOUT_PATH"/*)
            echo "Removing $folder"
            rm -rf "$folder"
            REMOVED=$((REMOVED + 1))
            ;;
    esac
done
echo "@devhub {\"toast\": \"Removed $REMOVED DerivedData folder(s)\"}"
"""#),
        ExampleFile(path: "scripts/list-devices.sh", isExecutable: true, content: #"""
#!/bin/zsh
# Source script for a custom tab section: prints rows with their own actions.
set -u
python3 - <<'PY'
import json, subprocess
raw = subprocess.run(["xcrun", "simctl", "list", "devices", "booted", "-j"], capture_output=True, text=True).stdout
devices = json.loads(raw or "{}").get("devices", {})
rows = []
for runtime, items in devices.items():
    for device in items:
        rows.append({
            "id": device["udid"],
            "title": device["name"],
            "subtitle": runtime.split(".")[-1].replace("-", " "),
            "tags": [{"text": device["state"].lower(), "tint": "green"}],
            "actions": [
                {"title": "Open", "run": {"command": ["open", "-a", "Simulator", "--args", "-CurrentDeviceUDID", device["udid"]]}},
                {"title": "Shut down", "run": {"command": ["xcrun", "simctl", "shutdown", device["udid"]]}, "confirm": "Shut down this simulator?"}
            ]
        })
print("@devhub " + json.dumps({"view": {"rows": rows}}))
PY
"""#),
        ExampleFile(path: "scripts/regenerate-resources.sh", isExecutable: true, content: #"""
#!/bin/zsh
# devhub: title = Regenerate resources
# devhub: subtitle = Runs the resource generator after asset or string changes
# devhub: icon = wand.and.stars
# devhub: tint = purple
# devhub: input = target, Target, choice, App|Widget
# devhub: input = clean, Clean first, toggle, false
# devhub: placements = home.scripts
# devhub: cwd = checkout
set -euo pipefail
echo "@devhub {\"progress\": \"Generating for $DEVHUB_INPUT_TARGET\"}"
if [ "$DEVHUB_INPUT_CLEAN" = "true" ]; then
    echo "Cleaning generated files first"
fi
echo "Replace this line with the generator command"
echo "@devhub {\"toast\": \"Resources generated\"}"
"""#),
        ExampleFile(path: "scripts/sim-status.sh", isExecutable: true, content: #"""
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
"""#)
    ]
}
