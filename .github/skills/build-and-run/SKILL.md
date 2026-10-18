---
name: build-and-run
description: "Build, test, smoke-run and install DevHub from the command line: Scripts/build.sh, test.sh, run.sh, install.sh, smoke.sh, the layer and anonymity checks, headless snapshots, the DEVHUB_* debug launch switches, the build settings that matter, and fixes for common xcodebuild, swift test and menu bar app problems."
---

# Build and Run

## Commands

| Command | Result |
|---|---|
| `Scripts/build.sh [Debug\|Release]` | `check-layers.sh` (`layers: ok`), `check-anonymous.sh` (`anonymous: ok`), then `xcodebuild -quiet` into `DerivedData/`; prints the `.app` path. `SKIP_LAYER_CHECK=1` skips the layer check while you iterate |
| `Scripts/test.sh [args]` | `swift test -q` on `Packages/DevHubKit`, one summary line. `--skip integration` skips the process suites, `--filter <Suite>` runs one suite |
| `Scripts/smoke.sh` | starts the Debug build for 3 s and prints `alive` or `dead` |
| `Scripts/run.sh` | Debug build, quits the running copy of this build, opens the new one |
| `Scripts/install.sh` | Release build copied to `/Applications/DevHub.app` and opened |
| `Scripts/make-launcher.sh` | creates `DevHub Launcher.app` (AppleScript) in the repo root that runs `run.sh`. Not committed |
| `Scripts/generate-example-config.sh` | rewrites `DevHubDomain/Policies/ExampleConfig.swift` from `docs/examples/devhub/` |

A clean build prints `layers: ok`, `anonymous: ok` and the app path. Any other line is an error or a warning: fix it before the next step. When a build fails, filter the output: `Scripts/build.sh 2>&1 | grep -E "error:" | sed 's#.*/Sources/##' | sort -u`.

The scripts stop only the build of this repository: `pkill -f "^$APP/Contents/MacOS/DevHub"`. Another app called DevHub on the same machine keeps running.

## Before every commit

1. `Scripts/build.sh` is clean.
2. `Scripts/test.sh` prints `Test run with … passed`.
3. `Scripts/smoke.sh` prints `alive`.
4. A change to a view: look at it with `Scripts/run.sh` or a headless snapshot.

## Look at the UI without a screen

```sh
APP=DerivedData/Build/Products/Debug/DevHub.app
DEVHUB_PROJECT=/path/to/a/throwaway/repo DEVHUB_OPEN_PANEL=1 DEVHUB_TAB=git \
DEVHUB_SNAPSHOT=/path/in/scratchpad/git.png DEVHUB_SNAPSHOT_DELAY=3 "$APP/Contents/MacOS/DevHub" &
for i in $(seq 1 40); do [ -f /path/in/scratchpad/git.png ] && break; sleep 0.25; done
pkill -f "^$PWD/$APP/Contents/MacOS/DevHub"
```

Then read the picture. Snapshot trap: SwiftUI does not redraw a panel that is covered by other windows, and `cacheDisplay` does not draw some controls (a prominent button looks empty). Check the result on the command line as well.

Use a throwaway repository for anything that runs actions or git steps: `git init`, one commit, a bare remote (`git init --bare upstream.git`, `git remote add upstream …`, `git push -u upstream main`), and a `.devhub/project.json`.

## Debug launch switches

Debug builds only. `DevHubComposition/Debug/DebugLaunch.swift` reads them and calls the `debug…` methods in `DevHubPresentation/Shared/PresentationAssembly+Debug.swift` and `+DebugGitOps.swift`. The switches after `DEVHUB_OPEN_PANEL` need `DEVHUB_OPEN_PANEL=1`.

| Switch | Effect |
|---|---|
| `DEVHUB_PROJECT=<path>` | adds and selects a project (saved) |
| `DEVHUB_RUN_ACTION=<id>[,<id>]` | runs config actions with their default inputs |
| `DEVHUB_REQUEST_ACTION=<id>` | opens the input prompt of one action on Home |
| `DEVHUB_GIT_OPS=<step>,<step>` | runs git and worktree steps and waits until the stores are idle after each one: `fetch`, `pull`, `push`, `forcepush`, `rebase`, `continueop`, `abortop`, `updatebase`, `stash:<msg>`, `popstash`, `switch:<b>`, `switchstash:<b>`, `update:<b>`, `delete-branch:<b>`, `checkout-remote:<remote/b>`, `select:<path>\|main`, `stage:<path>`, `unstage:<path>`, `discard:<path>`, `stageall`, `unstageall`, `commit:<msg>`, `commitpush:<msg>`, `amend:<msg>`, `action:<id>`, `wt-create:<b>`, `wt-delete:<b>`, `wt-prune`, `wt-fetch`, `sleep:<s>`. It writes to the repository: use a throwaway one |
| `DEVHUB_BUILD_RUN=<udid or name>` | runs Build & Run on that simulator and waits until it ends; `DEVHUB_BUILD_PROFILE=<id>` picks a launch profile, `DEVHUB_LAUNCH_ID=<id>` sets the launch identity of that simulator, `DEVHUB_BUILD_BRANCH=<branch>` builds that branch (a worktree is created when it has no checkout) |
| `DEVHUB_MOCK=<udid or name>,<off\|passthrough\|mock>[,<set name>]` | sets the mock server mode (and the set) of that simulator, runs Apply & Relaunch and selects the simulator in the Network tab |
| `DEVHUB_LOG_STREAMS=<udid or name>[,<udid or name>]` | starts a log stream on each simulator; the Logs tab shows one chip per stream |
| `DEVHUB_OPEN_PANEL=1` | opens the panel at launch |
| `DEVHUB_TAB=<id>` | selects a tab (saved) |
| `DEVHUB_SHOW_OUTPUT=1` | opens the Output panel (saved) |
| `DEVHUB_SNAPSHOT=<png path>` | writes a picture of the panel |
| `DEVHUB_SNAPSHOT_DELAY=<seconds>` | waits longer before the picture (default 1) |

## Build settings that matter (app target)

| Setting | Value | Why |
|---|---|---|
| `ENABLE_APP_SANDBOX` | `NO` | shell commands |
| `CODE_SIGN_STYLE` | `Automatic`, no team | ad-hoc "Sign to Run Locally" |
| `INFOPLIST_KEY_LSUIElement` | `YES` | no Dock icon |
| `PRODUCT_BUNDLE_IDENTIFIER` | `devteams.DevHub` | keeps the preferences of the first generic app |
| `SWIFT_VERSION` | `6.0` | Swift 6 language mode |

The package sets its own Swift settings in `Packages/DevHubKit/Package.swift` (tools 6.2, upcoming features `MemberImportVisibility`, `InferIsolatedConformances`, `NonisolatedNonsendingByDefault`). Never touch the file reference sections of `project.pbxproj`.

## Common problems

| Symptom | Fix |
|---|---|
| tests read wrong enum values or the test process dies with signal 6 right after an enum change | `rm -rf Packages/DevHubKit/.build`, then `Scripts/test.sh` again |
| `Fatal access conflict detected` in a test run | a closure changed a list that is being changed; look for a `deinit` that unsubscribes while `AppEvents` removes a handler |
| `… is not available due to missing import of defining module` | `MemberImportVisibility`: import the module that defines the member |
| a store test times out right after a build | the main actor is busy; `waitUntil` waits 10 s by default, never shorten it |
| `anonymous: …` lines | a name, bundle ID, suite or host that is not a sample value; see `.claude/rules/anonymity.md` |
| build ok, nothing visible | menu bar app: look for the icon; `pgrep -f "$PWD/DerivedData"` confirms it runs |
| `resource fork, Finder information, or similar detritus not allowed` | `xattr -cr DevHub/` |
| a script is blocked after a copy | `xattr -d com.apple.quarantine <file>` |
| preview fails to render | the preview needs `.previewEnvironment()` |
| Accessibility prompt again after a rebuild | expected with ad-hoc signing; allow DevHub again in System Settings |
