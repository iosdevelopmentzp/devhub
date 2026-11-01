# ADR 007. Operations with steps, and daily tools

Date: 2026-11-01. Status: in progress (see the plan and the step log).

This page is the brief for the implementation. The next session reads it first, then the files it names, then goes on with the first open step of the plan.

## Context

The owner asked for two things.

1. **Clear progress and clear failures.** Many places run commands: the Git tab, the commit box, config actions and scripts in every placement, worktrees, pull request actions, simulators. While a command runs, the panel shows at most a title with "…" or a spinner on a tile. When it fails, DevHub writes a red line in Recent and opens the Output panel, where the reason is somewhere in the raw transcript. A script that exits with a non-zero code without an `error` line shows only "Exited with code 1." Reading the Output panel is not convenient.
2. **Daily tools** from the review of the daily routine (2026-11-01): crash reports of the app on a simulator, the data of the app on a simulator, "changed since your review" in pull requests, AI text for a request and a commit, "Explain" for a request, reviewers and assignees, disk cleanup, a Xcode version per project.

The owner also asked that DevHub does not start background processes that eat memory. On 2026-11-01 the installed Release build used about 145 MB with no child processes and 0 % CPU while idle. Every periodic read is a timer inside the app: open requests every 5 minutes (2 while the panel is closed), the usage strip every 5 minutes, a watched request and an auto re-run plan every minute, and only while one exists.

## Decisions

### D1. Operations

1. An **operation** is one action that the user started: a push, a rebase, a config action, a bootstrap, a merge. `OperationScope.current` (a Domain `@TaskLocal` UUID) is set while the operation works. `ShellRunner` reads it when a command starts and puts it into the `started` command event, so every command of the operation knows its operation. No store passes an ID by hand.
2. `OperationLog` (Presentation, shared) keeps the operations of this session: title, origin (where it started, for example `git`, `changes`, `action:<id>`, `worktree:<path>`), state, progress text and fraction (the script `progress` line), start and end time, failure message, retry. It keeps every running operation and the last 30 finished ones, in memory only.
3. The **steps** of an operation are its command log entries in order. A read command (`git status`, `git rev-parse`) shows only when it failed.
4. `FailureDigestPolicy` (Domain) picks the lines that explain a failure from the output of the failed step: lines with `error`, `fatal`, `failed`, `rejected`, `conflict`, `denied`, `not found`, `hint` and similar words, else the last lines. At most 8 lines.
5. An **operation card** shows the operation at the place where it started:
   - running: the title, the time since the start, the steps with a spinner, a check mark or a cross, the last output line of the running step, and the progress bar of a script;
   - failed: "<title> failed", the message, the failed step with its exit code, the digest lines, and the buttons Retry (when the place can repeat the action), Copy Error, Full Output (the whole output of the failed step inside the card) and Dismiss;
   - succeeded: one green line with the time, which goes away after a few seconds.
6. The footer shows the operations: a spinner and the title of a running one ("2 running" for more), or a red "1 failed" until it is seen. A click opens a list of the operations of this session with the same cards.
7. The Output panel stays the full transcript. It no longer opens by itself on a failure, because the card shows the reason. "Open When a Command Fails" in its filter menu brings the old behaviour back.
8. Build & Run and the test runs of a worktree keep their own panels: they already show steps, counts and errors.

### D2. Crash reports (later step)

No new process and no timer. After DevHub launches the app on a simulator, a file system event source on `~/Library/Logs/DiagnosticReports` (one file descriptor, the kernel wakes DevHub when a file is added) reads only new `.ips` files of that app from a simulator. The run bar, Recent and a notification show "Example App crashed · <exception> · <top frame of the app>", with the report and "Fix with AI".

### D3. App data (later step)

The menu of a simulator row gets "App Data…": a panel under the row with the `UserDefaults` of the app and of its app group (`simctl spawn … defaults export`), edit and delete of a key, the Documents, Caches and Application Support folders, the database files with their size, and "Reset App Data" with an inline confirmation.

### D4. Changed since your review (later step)

A switch in Settings → Pull Requests ("Remember what I reviewed", on by default). DevHub saves, per request, the last commit and a hash of the diff of each file when you approve, comment, ask for changes or mark every file as viewed. When the request has new commits, the details say "4 files changed since your review on <date>", offer "Show Only These" and mark those files. "Viewed" is saved and is cleared for a file whose diff changed. "Forget" removes the mark. No extra request to the host.

### D5. AI text and Explain (later step)

One-shot text through the command line tools: `claude -p` or `copilot -p`. Settings choose the tool; the button menu can choose it for one run. "Write with AI" in the new request form (title and description from the diff, the template and the ticket) and in the commit box (a message from the staged diff). "Explain" in the details of a request: what it changes, risky places, and what changed since your review. Every run is an operation with its steps and Stop.

### D6. Reviewers and assignees (later step)

The review block of the details gets a menu that adds and removes reviewers and assignees: `gh pr edit --add-reviewer/--remove-reviewer/--add-assignee/--remove-assignee`, `glab mr update --reviewer/--assignee`. The people come from the host (assignable users or project members).

### D7. Disk cleanup (later step)

Settings → Disk. Only Xcode and tool folders that every Mac has: DerivedData folders whose project no longer exists (`WorkspacePath` in their `info.plist`), all DerivedData by project, unavailable simulators (`xcrun simctl delete unavailable`), simulator runtimes, Archives, iOS DeviceSupport, the SwiftPM and CocoaPods caches. Each line shows its size and deletes after an inline confirmation.

### D8. Xcode per project (later step)

`xcode.developerDir` in `project.json`, and a choice per project in Settings → Projects (the Xcode apps that Spotlight finds), the choice first. DevHub passes `DEVELOPER_DIR` to `xcodebuild`, `xcrun` and `xed`. The Doctor shows the Xcode of the project.

## Plan

- [x] 1. D1 core: `OperationScope`, the operation ID in command events, `OperationLog`, `FailureDigestPolicy`, the card, the footer list, the Output panel switch. Wired into `ActionRunner` (Git, commit box, simulators, messaging) and config actions in every placement.
- [x] 2. D1 in the other places: worktrees (fetch, prune, clean, create, delete, bootstrap) and pull request actions (row, details pane, request window). Settings has no long command: its Doctor check is a read.
- [x] 3. D8 Xcode per project.
- [x] 4. D2 crash reports.
- [x] 5. D3 app data.
- [x] 6. D4 changed since your review.
- [ ] 7. D6 reviewers and assignees.
- [ ] 8. D5 AI text and Explain.
- [ ] 9. D7 disk cleanup.

## Step log

| Commit | Step |
|---|---|
| `54057c8` | Step 1: `OperationScope`, the operation ID in command events, `OperationLog`, `FailureDigestPolicy`, the card, the footer list, the Output panel switch; `ActionRunner` and config actions. |
| `4b5c45f` | Step 2: worktree actions (`.worktrees`, `.worktree(path)`) and pull request actions (`.pullRequest(number)`) as operations; `OperationLog.perform`; a card title in `PullRequestActionTexts`. |
| `221f163` | Step 3: Xcode per project: `Project.developerDir`, `xcode.developerDir`, `DeveloperDirPolicy`, `DeveloperDirState` in `ShellRunner`, `XcodeInstallationRepository`, `ToolEnvironmentRepository`, `XcodeSelectionStore` and the picker in Settings → Projects. |
| `a41771e` | Step 4: crash reports: `CrashReport`, `CrashReportRepository`, `CrashReportPolicy`, `IPSCrashReportParser`, `FileCrashReportRepository` (one `DispatchSource` on `~/Library/Logs/DiagnosticReports`), `CrashReportsStore` and the crash block in the run bar. |
| `923fdb1` | Step 5: app data: `AppDataRepository`, `SimctlAppDataRepository` (`get_app_container`, `spawn defaults export\|write\|delete`), `DefaultsExportParser`, `AppGroupListParser`, `AppDataScanner`, `AppDefaultsPolicy`, `AppDataStore` and the "App Data…" panel under a simulator row. |
