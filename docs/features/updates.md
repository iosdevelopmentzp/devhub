# Updates

DevHub updates itself from the pushed `main` branch of its own repository. The button lives in the footer, next to the operations indicator, and is hidden when there is nothing to do.

Code: `Packages/DevHubKit/Sources/DevHubPresentation/Features/Updates/`, `DevHubData/Updates/`, `Scripts/install.sh`, `Scripts/update.sh`, `Scripts/update-status.sh`. Decisions: ADR 014.

## What it shows

| State | Footer | Click |
|---|---|---|
| nothing new, or a development build | hidden | — |
| new commits on `origin/main` | "Update available · N" in blue | a popover with the commit subjects and "Update Now" |
| an update runs | a spinner with the phase and the time since the start: "Getting changes · 0:04", "Building · 1:20", "Installing · 2:02" | nothing |
| the last update failed | "Update failed" in orange | a popover with the message, the log of the update and "Try Again" |

After the new build opens, a toast says "Updated to <short hash>" once.

## How it works

1. `Scripts/install.sh` (run once from the repository) builds, creates the build clone `~/Library/Application Support/DevHub Generic/source` when it is missing, installs the app and writes `update/installed.json` next to the clone.
2. Every 5 minutes, and at launch, the app runs `git fetch` in the build clone and compares the installed commit with `origin/main`. A build from commits that are not on the remote shows no update until they are pushed.
3. "Update Now" starts `Scripts/update.sh` from the build clone, detached from the app. The script writes `update/status.json` at each phase and its output to `update/update.log`.
4. The app reads the status every second. When the phase is `installing`, the app quits itself; the script swaps the bundle in `/Applications`, writes `installed.json` and opens the new app.
5. A failed build leaves the old app running with the failure in the footer. "Try Again" starts the script again.

"Check for Updates" in the DevHub menu and in the menu of the status item runs the check now and reports the result as a toast. A development build (no `installed.json`) never checks.

## Debug

`DEVHUB_UPDATE_STATE=available|running|failed` puts the button into a state for a headless snapshot (`build-and-run` skill).
