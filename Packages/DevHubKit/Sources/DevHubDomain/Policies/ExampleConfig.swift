import Foundation

package enum ExampleConfig {
    package static let files: [ExampleFile] = [
        ExampleFile(path: "README.md", text: #"""
# Example `.devhub/` folder

Copy this folder into a project as `.devhub/` and adjust the values. Every field is explained in `docs/extensions.md`; `docs/customization.md` maps a need to the mechanism.

- `project.json`: how the project builds and runs, base branch, worktree rules, launch profiles with their mock server upstream, the launch identity, the network mocks, log filter, Home grid order.
- `actions/`: buttons with placements, inputs and confirmation.
- `scripts/`: executables. A script with a `# devhub:` header becomes a row on Home without a JSON file. The helper scripts that an action, a tab or `simulators.statusScript` runs have `placements = palette`, so Home does not list them twice.
- `tabs/`: `qa.json`, a custom tab built from actions and a source script; `chat.json`, a tab of chat commands with shared inputs (environment and user ID), `copy` actions that put the rendered command on the clipboard and open the channel, and a Recent list with Resend.
"""#, isExecutable: false),
        ExampleFile(path: "project.json", text: #"""
{
  "name": "Example App",
  "kind": "xcode",
  "ai": {
    "commands": {
      "claude": "claude \"$(cat {prompt})\"",
      "copilot": "copilot -i \"$(cat {prompt})\""
    }
  },
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
    },
    "pullRequests": {
      "targets": ["main", "release"],
      "staleDays": 10,
      "hiddenFiles": ["*.lock"],
      "fileGroups": [
        { "name": "Tests", "patterns": ["*Tests/*", "*Tests.swift"], "hidden": true },
        { "name": "Project", "patterns": ["*.xcodeproj/*", "*.resolved"], "hidden": true },
        { "name": "UI", "patterns": ["*/Calls/*", "*UI/*"] }
      ],
      "defaults": { "draft": true, "deleteSourceBranch": true, "squash": false }
    }
  },
  "launch": {
    "profiles": [
      { "id": "staging", "title": "Staging", "env": { "API_ENV": "staging" }, "defaults": [ { "suite": "group.com.example.app", "key": "environment", "value": "staging" } ], "storage": { "suite": "group.com.example.app", "key": "environment" }, "upstream": "https://api-qa.example.com", "tint": "indigo" },
      { "id": "production", "title": "Production", "env": { "API_ENV": "production" }, "cleanInstall": true, "upstream": "https://api.example.com", "production": true }
    ],
    "identity": { "variable": "APP_DEVICE_ID", "keptVariable": "APP_KEEP_DEVICE_ID", "args": ["-skipOnboarding", "YES"], "idPrefix": "devhub-" }
  },
  "network": { "baseURLVariable": "APP_BASE_URL", "mocksFolder": "Tests/Mocks" },
  "tracker": { "kind": "jira", "project": "ABC", "statuses": ["To Do", "In Progress", "In Review", "Done"], "startStatus": "In Progress", "branchFormat": "feature/{key}-{slug}" },
  "logs": { "subsystem": "com.example.app" },
  "simulators": { "statusScript": "scripts/sim-status.sh" },
  "home": { "quickActions": ["builtin.buildRun", "builtin.runAttach", "clean-derived-data", "open-ci", "builtin.terminal", "builtin.copyBranch"] }
}
"""#, isExecutable: false),
        ExampleFile(path: "actions/chat-build.json", text: #"""
{
  "id": "chat-build",
  "title": "Build a branch on CI",
  "subtitle": "/cibot build {branch}",
  "icon": "hammer",
  "placements": ["tab.chat"],
  "run": { "copy": "/cibot build {branch}", "open": "slack://channel?team=T0000000&id=C0000000" },
  "inputs": [
    { "key": "branch", "title": "Branch", "type": "branch", "default": "current" }
  ]
}
"""#, isExecutable: false),
        ExampleFile(path: "actions/chat-coins.json", text: #"""
{
  "id": "chat-coins",
  "title": "Top up coins",
  "subtitle": "{env} coins {user} {amount}",
  "icon": "plus.circle",
  "placements": ["tab.chat"],
  "run": { "copy": "{env} coins {user} {amount}", "open": "slack://channel?team=T0000000&id=C0000000" },
  "inputs": [
    { "key": "amount", "title": "Coins", "type": "number", "default": 10000, "recent": true }
  ]
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
        ExampleFile(path: "actions/clear-app-caches.json", text: #"""
{
  "id": "clear-app-caches",
  "title": "Clear App Caches",
  "subtitle": "Removes Library/Caches of the app and its app groups on the chosen simulator",
  "icon": "eraser",
  "placements": ["network.toolbar", "simulators.row", "simulators.appData"],
  "run": { "script": "scripts/clear-app-caches.sh" },
  "confirm": "Delete the caches of the app and its app groups on this simulator? Saved logins stay.",
  "refresh": ["network", "simulators"]
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
        ExampleFile(path: "actions/open-pr-files.json", text: #"""
{
  "id": "open-pr-files",
  "title": "Open Changed Files",
  "subtitle": "The files page of this pull request on GitHub",
  "icon": "doc.text.magnifyingglass",
  "tint": "indigo",
  "placements": ["pullRequests.row"],
  "run": { "open": "{pr_url}/files" },
  "when": { "host": "github" }
}
"""#, isExecutable: false),
        ExampleFile(path: "scripts/clean-derived-data.sh", text: #"""
#!/bin/zsh
# devhub: title = Clean DerivedData
# devhub: placements = palette
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
        ExampleFile(path: "scripts/clear-app-caches.sh", text: #"""
#!/bin/zsh
set -euo pipefail
if [ -z "$DEVHUB_DATA_CONTAINER" ]; then
    echo "@devhub {\"error\": \"$DEVHUB_BUNDLE_ID is not installed on $DEVHUB_SIMULATOR_NAME\"}"
    exit 1
fi
echo "Profile: ${DEVHUB_PROFILE:-none} · host: ${DEVHUB_HOST:-unknown}"
rm -rf "$DEVHUB_DATA_CONTAINER/Library/Caches"
mkdir -p "$DEVHUB_DATA_CONTAINER/Library/Caches"
while IFS=$'\t' read -r group folder; do
    [ -n "$folder" ] || continue
    rm -rf "$folder/Library/Caches"
    mkdir -p "$folder/Library/Caches"
done <<< "$DEVHUB_GROUP_CONTAINERS"
echo "@devhub {\"toast\": \"Cleared the caches of $DEVHUB_BUNDLE_ID on $DEVHUB_SIMULATOR_NAME ($DEVHUB_SIMULATOR_STATE)\"}"
"""#, isExecutable: true),
        ExampleFile(path: "scripts/list-devices.sh", text: #"""
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
"""#, isExecutable: true),
        ExampleFile(path: "tabs/chat.json", text: #"""
{
  "id": "chat",
  "title": "Chat",
  "icon": "bubble.left.and.text.bubble.right",
  "searchPrompt": "Search chat commands",
  "inputs": [
    { "key": "env", "title": "Environment", "type": "choice", "options": [{ "value": "/qabot", "title": "QA" }, { "value": "/prodbot", "title": "PROD", "confirm": "Copy a command for PROD?" }], "default": "/qabot" },
    { "key": "user", "title": "User ID", "type": "text", "recent": true, "placeholder": "the ID from the profile page" }
  ],
  "sections": [
    { "title": "Accounts", "actions": ["chat-coins"] },
    { "title": "CI", "actions": ["chat-build"] }
  ]
}
"""#, isExecutable: false),
        ExampleFile(path: "tabs/qa.json", text: #"""
{
  "id": "qa",
  "title": "QA",
  "icon": "wrench.and.screwdriver",
  "searchPrompt": "Search QA tools",
  "placement": "bar",
  "sections": [
    { "title": "Project", "actions": ["clean-derived-data", "open-ci", "script:regenerate-resources"] },
    { "title": "Booted simulators", "source": { "script": "scripts/list-devices.sh", "refresh": "onOpen" } }
  ]
}
"""#, isExecutable: false)
    ]
}
