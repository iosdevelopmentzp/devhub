import Foundation

package enum ExampleConfig {
    package static let files: [ExampleFile] = [
        ExampleFile(path: "README.md", text: #"""
# Example `.devhub/` folder

Copy this folder into a project as `.devhub/` and adjust the values. Every field is explained in `docs/extensions.md`.

- `project.json`: how the project builds and runs, base branch, worktree rules, launch profiles, log filter, Home grid order.
- `actions/`: buttons with placements, inputs and confirmation.
- `scripts/`: executables with a `# devhub:` header; they become rows on Home without a JSON file.
- `tabs/`: a custom tab built from actions and a source script.
"""#, isExecutable: false),
        ExampleFile(path: "project.json", text: #"""
{
  "name": "Example App",
  "kind": "xcode",
  "xcode": {
    "container": "ExampleApp.xcworkspace",
    "scheme": "ExampleApp",
    "configuration": "Debug",
    "schemes": ["ExampleApp", "ExampleWidget"],
    "bundleIDs": { "ExampleApp": "com.example.app", "ExampleApp/Debug": "com.example.app.dev" }
  },
  "git": {
    "baseBranch": "origin/main",
    "commitPrefix": { "pattern": "^([A-Z]+-\\d+)", "format": "$1: " },
    "worktrees": {
      "folder": ".worktrees",
      "include": ["Config/Local.xcconfig"],
      "bootstrap": "Scripts/bootstrap.sh",
      "bootstrapMarker": "Pods"
    }
  },
  "launch": {
    "profiles": [
      { "id": "staging", "title": "Staging", "env": { "API_ENV": "staging" }, "defaults": [ { "suite": "group.com.example.app", "key": "environment", "value": "staging" } ] },
      { "id": "production", "title": "Production", "env": { "API_ENV": "production" }, "cleanInstall": true }
    ]
  },
  "logs": { "subsystem": "com.example.app" },
  "simulators": { "statusScript": "scripts/sim-status.sh" },
  "home": { "quickActions": ["builtin.buildRun", "builtin.runAttach", "clean-derived-data", "open-ci", "builtin.terminal", "builtin.copyBranch"] }
}
"""#, isExecutable: false),
        ExampleFile(path: "actions/clean-derived-data.json", text: #"""
{
  "id": "clean-derived-data",
  "title": "Clean DerivedData",
  "subtitle": "Removes the DerivedData folder of this project",
  "icon": "trash",
  "tint": "red",
  "placements": ["home.quickActions", "git.pills"],
  "run": { "script": "scripts/clean-derived-data.sh" },
  "cwd": "checkout",
  "confirm": "Delete DerivedData for this checkout? The next build takes longer.",
  "refresh": ["worktrees"]
}
"""#, isExecutable: false),
        ExampleFile(path: "actions/open-ci.json", text: #"""
[
  {
    "id": "open-ci",
    "title": "Open CI",
    "subtitle": "Pipelines of the current branch",
    "icon": "play.rectangle",
    "tint": "blue",
    "placements": ["home.quickActions", "git.pills", "git.branchRow"],
    "run": { "open": "https://ci.example.com/pipelines?branch={branch}" }
  },
  {
    "id": "lint",
    "title": "Lint",
    "subtitle": "Runs the linter in the terminal",
    "icon": "checkmark.seal",
    "tint": "green",
    "placements": ["git.pills"],
    "run": { "terminal": "make lint" },
    "cwd": "checkout",
    "when": { "git": "dirty" }
  }
]
"""#, isExecutable: false),
        ExampleFile(path: "scripts/clean-derived-data.sh", text: #"""
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
"""#, isExecutable: true),
        ExampleFile(path: "scripts/list-devices.sh", text: #"""
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
"""#, isExecutable: true),
        ExampleFile(path: "scripts/regenerate-resources.sh", text: #"""
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
"""#, isExecutable: true),
        ExampleFile(path: "scripts/sim-status.sh", text: #"""
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
"""#, isExecutable: true),
        ExampleFile(path: "tabs/qa.json", text: #"""
{
  "id": "qa",
  "title": "QA",
  "icon": "wrench.and.screwdriver",
  "searchPrompt": "Search QA tools",
  "sections": [
    { "title": "Project", "actions": ["clean-derived-data", "open-ci", "script:regenerate-resources"] },
    { "title": "Booted simulators", "source": { "script": "scripts/list-devices.sh", "refresh": "onOpen" } }
  ]
}
"""#, isExecutable: false)
    ]
}
