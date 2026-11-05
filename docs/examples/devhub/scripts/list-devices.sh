#!/bin/zsh
# devhub: title = Booted simulators
# devhub: placements = palette
# Source script for a custom tab section: prints rows with their own actions.
set -u
python3 - <<'PY'
import json, subprocess
raw = subprocess.run(["xcrun", "simctl", "list", "devices", "booted", "-j"], capture_output=True, text=True).stdout
devices = json.loads(raw or "{}").get("devices", {})
open_device = 'open -a "$(xcode-select -p)/Applications/Simulator.app" --args -CurrentDeviceUDID "$1" 2>/dev/null || open "devices://device/open?id=$1"'
rows = []
for runtime, items in devices.items():
    for device in items:
        rows.append({
            "id": device["udid"],
            "title": device["name"],
            "subtitle": runtime.split(".")[-1].replace("-", " "),
            "tags": [{"text": device["state"].lower(), "tint": "green"}],
            "actions": [
                {"title": "Open", "run": {"command": ["/bin/sh", "-c", open_device, "open", device["udid"]]}},
                {"title": "Shut down", "run": {"command": ["xcrun", "simctl", "shutdown", device["udid"]]}, "confirm": "Shut down this simulator?"}
            ]
        })
print("@devhub " + json.dumps({"view": {"rows": rows}}))
PY
