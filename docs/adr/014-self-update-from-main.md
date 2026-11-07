# ADR 014. Self-update from the pushed main branch

Date: 2026-11-07. Status: done, 2026-11-07 (see the step log).

## Context

The app is built from source on the owner's Mac and installed with `Scripts/install.sh`. Until now, git hooks (`post-commit`, `post-merge`) ran `Scripts/auto-install.sh` after every commit on `main` of the working copy, so a half-done local commit replaced the installed app, and a clone without the hooks never updated. The owner asked for the update flow of the spec "Self-update from a git branch": the running app checks the remote `main`, shows what is new, updates on a click, and reports the result after it opens again.

## Decisions

### D1. A build clone that only the updater touches

`install.sh` creates `~/Library/Application Support/DevHub Generic/source` with `git clone --branch main <origin of this checkout>` when it is missing, and writes `update/installed.json` (`commit`, `branch`, `source`, `installedAt`) next to it after every install. `Scripts/update.sh` runs from that clone: a lock file with its pid, `status.json` with the phase `fetching`, `git fetch` and `reset --hard origin/main`, then the `install.sh` of the clone, which writes the phases `building`, `installing` and `done`, or `failed` with a message. Every JSON file is written to a temporary name and moved, so the app never reads a half file. `DEVHUB_SUPPORT_DIR` and `DEVHUB_UPDATE_BRANCH` change the folder and the branch for a test. The working copy of the owner is never touched, so local commits, other branches and uncommitted edits do not reach the installed app.

### D2. The app checks, starts and follows, and quits itself for the install

`UpdateRepository` (Domain) has `installed()`, `check(installed:)`, `start(installed:)`, `status()`, `isUpdateRunning()`, `clearStatus()` and `log()`. `FileUpdateRepository` (Data) reads the JSON files, runs `git fetch`, `git merge-base --is-ancestor` and `git log --format=%h%x1f%s` in the clone through `ShellRunner`, and starts the script detached with `zsh -c '"…/update.sh" > update.log 2>&1 < /dev/null &!'`, so the script survives when the app quits. `UpdateCheckPolicy` turns the git results into `upToDate`, `available(commits)` or `unknownInstalledCommit` (the installed commit is not on the remote, for example a build from unpushed commits: no button). `UpdateStore` (Presentation) checks at launch and every 5 minutes, reads `status.json` every second while an update runs, and asks the app to quit (`onInstalling`, set by `AppWindows` to `NSApp.terminate`) when the phase becomes `installing`; `install.sh` waits up to 5 s for that quit before it stops the process by its path. The script never sends an Apple event to the app, so no Automation permission is needed. A development build has no `installed.json`: the store stays idle and never checks.

### D3. After launch, the status file tells what happened

`UpdateLaunchPolicy` reads `status.json` at launch: `done` with the installed commit shows "Updated to <short hash>" once and deletes the file; `done` with another commit only deletes it; `failed` keeps the failure with the log; a running phase with a live pid in the lock is followed, without a live pid it is a failure. The same liveness check runs while the app follows an update, after the third poll, so a script that dies leaves no spinner behind.

### D4. One footer button and a menu item

`UpdateIndicator` sits in the footer after the operations indicator: hidden when idle, "Update available · N" (blue) with a popover of the commit subjects and "Update Now", a spinner with "Building · 1:20" while running (the elapsed time from `startedAt`, `ElapsedTime` in DevHubUI), and "Update failed" in orange with the message, the log and "Try Again". "Check for Updates" in the DevHub menu and the status item menu runs the check now and reports the result as a toast. A check is skipped while an update runs or after a failure, until the user tries again.

### D5. The hooks are gone

`Scripts/auto-install.sh` and `Scripts/install-hooks.sh` are removed, and the owner's `post-commit` and `post-merge` hooks with them. Updates come only from the pushed `main`, in one place.

## Consequences

- One `git fetch` in the build clone every 5 minutes; it lands in the command log like every process.
- The first `install.sh` of a clone takes a full Release build in the build clone's own `DerivedData/Install`; later builds are incremental.
- `DEVHUB_UPDATE_STATE=available|running|failed` puts the footer button into a state for a headless snapshot.

## Step log

| Commit | What |
|---|---|
