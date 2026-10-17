---
name: build-and-run
description: "Build, smoke-run and install DevHub from the command line: Scripts/build.sh, run.sh, install.sh, make-launcher.sh, the headless launch check, the build settings that matter, and fixes for common xcodebuild and menu bar app problems."
---

# Build and Run

## Commands

| Command | Result |
|---|---|
| `Scripts/build.sh` | Debug build into `DerivedData/`, prints the `.app` path. Use after every code change |
| `Scripts/build.sh Release` | same with Release |
| `Scripts/run.sh` | Debug build, quits a running DevHub, opens the new one. The icon appears in the menu bar |
| `Scripts/install.sh` | Release build copied to `/Applications/DevHub.app` and opened |
| `Scripts/make-launcher.sh` | creates `DevHub Launcher.app` (AppleScript, `osacompile`) in the repo root that runs `run.sh` and shows an alert on failure. Not committed |
| `DevHub.command` | repo root; double-click in Finder runs `Scripts/run.sh` |

`build.sh` runs `xcodebuild -quiet`, so a clean build prints only the app path. Any other output is an error or a warning and must be fixed before the next step.

Script skeletons:

```sh
#!/bin/zsh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG="${1:-Debug}"
DERIVED="$ROOT/DerivedData"
xcodebuild -project "$ROOT/DevHub.xcodeproj" -scheme DevHub -configuration "$CONFIG" \
    -destination 'platform=macOS' -derivedDataPath "$DERIVED" -quiet build
echo "$DERIVED/Build/Products/$CONFIG/DevHub.app"
```

```sh
#!/bin/zsh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$("$ROOT/Scripts/build.sh" Debug | tail -1)"
pkill -x DevHub || true
open "$APP"
```

## Headless smoke check

Run it before every commit. The remote must always hold an app that builds and launches.

```sh
APP="$(Scripts/build.sh | tail -1)"
"$APP/Contents/MacOS/DevHub" & PID=$!
sleep 3
kill -0 $PID && echo alive || echo crashed
kill $PID
```

## Look at the UI without a screen

```sh
DEVHUB_OPEN_PANEL=1 DEVHUB_TAB=home DEVHUB_SNAPSHOT=/tmp/home.png DerivedData/Build/Products/Debug/DevHub.app/Contents/MacOS/DevHub &
sleep 3.5; pkill -x DevHub
```

Then read `/tmp/home.png`. `DEVHUB_TAB` is saved as the selected tab, so set it back to `home` afterwards. Filter build output with `Scripts/build.sh 2>&1 | grep -E 'error|warning'` when a build fails: the failure dump is very long.

## Debug launch switches

Read at launch by `App/DebugLaunch.swift`, `DebugLaunch+Logs.swift` and `DebugGitOps.swift`. Switches with a panel (`DEVHUB_TAB`, `DEVHUB_GIT_SEGMENT`, `DEVHUB_SEARCH`, `DEVHUB_AI_*`, `DEVHUB_USAGE_EXPAND`, `DEVHUB_SHOW_OUTPUT`, `DEVHUB_SNAPSHOT`) need `DEVHUB_OPEN_PANEL=1`.

| Switch | Effect |
|---|---|
| `DEVHUB_OPEN_PANEL=1` | opens the panel at launch |
| `DEVHUB_TAB=<id>` | selects a tab (saved, set it back to `home` afterwards) |
| `DEVHUB_SNAPSHOT=<png path>` | writes a picture of the panel and quits |
| `DEVHUB_SNAPSHOT_DELAY=<seconds>` | waits longer before the picture (default 1) |
| `DEVHUB_PROJECT=<path>` | adds and selects a project (saved) |
| `DEVHUB_RUN_ACTION=<id>[,<id>]` | runs actions with their default inputs |
| `DEVHUB_REQUEST_ACTION=<id>` | opens the input prompt of a script row |
| `DEVHUB_SEARCH=<text>` | fills the header search |
| `DEVHUB_SHOW_OUTPUT=1` | opens the Output panel |
| `DEVHUB_CREATE_EXAMPLE=1` | creates the `.devhub` example for the current project |
| `DEVHUB_GIT_SEGMENT=local\|remote\|history\|changes` | selects a Git segment |
| `DEVHUB_GIT_OPS=<op>,<op>` | runs git operations after 2 seconds (`fetch`, `pull`, `push`, `stash`, `switch:<b>`, `stage:<path>`, `commit:<msg>`, `wt-create:<b>`, `action:<id>`, `sleep:<s>` and more; the full list is in `App/DebugGitOps.swift`). It writes to the repository: use a throwaway one |
| `DEVHUB_LOG_STREAM=<udid>[:<process>],...` | starts log streams |
| `DEVHUB_LOG_REDACT_CHECK=1` | prints redaction samples to stderr |
| `DEVHUB_AI_SCOPE=<scope>` | sets the AI scope: `project` or `all` |
| `DEVHUB_AI_PROVIDER=<provider>` | sets the AI provider filter: `copilot`, `claude` or `both` |
| `DEVHUB_USAGE_EXPAND=1` | opens the usage details in the strip |

## Build settings that matter (app target)

| Setting | Value | Why |
|---|---|---|
| `ENABLE_APP_SANDBOX` | `NO` | shell commands |
| `CODE_SIGN_STYLE` | `Automatic`, no team | ad-hoc "Sign to Run Locally" |
| `INFOPLIST_KEY_LSUIElement` | `YES` | no Dock icon |
| `INFOPLIST_KEY_NSAppleEventsUsageDescription` | a sentence | Run & Attach drives Xcode through Apple Events |
| `SWIFT_VERSION` | `5.0` | Swift 5 language mode |
| `SWIFT_DEFAULT_ACTOR_ISOLATION` | `MainActor` | |
| `SWIFT_APPROACHABLE_CONCURRENCY` | `YES` | |
| `GENERATE_INFOPLIST_FILE` | `YES` | |

Change a setting with `sed` or `perl -pi` on the matching lines (Debug and Release). Never touch the file reference sections of `project.pbxproj`; the synchronized folder owns them.

## Common problems

| Symptom | Fix |
|---|---|
| `does not contain a scheme named "DevHub"` | open the project in Xcode once; the scheme is created on first open |
| build ok, nothing visible | menu bar app: look for the icon; `pgrep -x DevHub` confirms it runs |
| two icons | two instances: `pkill -x DevHub`, then `Scripts/run.sh` |
| `resource fork, Finder information, or similar detritus not allowed` | `xattr -cr DevHub/` |
| preview fails to render | the preview needs `.previewEnvironment()` |
| hover actions flicker | keep the actions in the tree and toggle `opacity` |
| `Main actor-isolated … cannot be used from a nonisolated context` | the type runs off the main actor: mark it `nonisolated` or make it an `actor`; parsers in Core are `nonisolated enum` |
| `Sending value of non-Sendable type` | the model needs `Sendable`; closures that cross actors need `@Sendable` |
| Accessibility prompt again after a rebuild | expected with ad-hoc signing; allow DevHub again in System Settings |
