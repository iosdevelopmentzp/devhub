# ADR 005: Window mode, ports from the main DevHub, and daily tools

- **Status**: done, 2026-10-27.
- **Scope**: `Packages/DevHubKit` (Shell, Settings, Home, Git, Pull Requests, Simulators, Build, AI, Palette), `DevHub.xcodeproj`, docs.

## Context

The main DevHub got new features after this repository was ported from it (its commits from 2026-10-19 to 2026-10-21): branch pins, labels and notes; Keep Mac awake; favorite AI sessions; drag to reorder favorite simulators; a fix for the Claude usage `limits` list; and a normal window instead of the menu bar panel.

The owner also asked for more comfort when working from any project: an easier project setup, faster project switching, better window handling and more pull request work inside DevHub.

## Decisions

1. **Two window modes.** Settings → General gets a "Window" picker with two values: "Menu bar panel" (the default, the current behaviour) and "Normal window". In window mode DevHub has one main window with a title bar, a Dock icon and a main menu. The close button and ⌘W hide the window, the menu bar icon and the global shortcut show it on the current desktop. This changes STATUS decision 2: the panel stays, but it is no longer the only mode.
2. **Right-click menu on the menu bar icon** in both modes: Show DevHub, the project list, Keep Mac awake, Settings…, Quit DevHub.
3. **Ports from the main DevHub** are checked against this repository's rules before they land. Nothing project-specific comes with them.
4. **Pull request comments.** A top-level comment on a request (both hosts), "Request Changes" with a message (GitHub only, GitLab has no such review state in `glab`), and a new thread on a diff line (both hosts).
5. **Checks and pipeline jobs** of a request show inside the details: the job list, the end of a failed job log, retry of one job.
6. **Project setup.** "Create .devhub Starter" writes a `project.json` with the values DevHub detected (remote, host kind, base branch, scheme, bundle ID). The example folder stays for a full reference.
7. **Project switching** from the ⌘K palette and with ⌃⌘1 to ⌃⌘9 (the order of Settings → Projects).
8. **Home "Today" card**: requests that wait for your review, your requests with failed checks, finished worktrees, booted simulators. A click opens the place.
9. **Simulator QA settings** per simulator: appearance, language and locale, text size, status bar override, location, privacy permissions, screenshot and video.
10. **Build log viewer**: after a build, errors and warnings as a list; a click opens `file:line` in the editor.

## Plan

- [x] P1. Claude usage: read the per-model weekly limits from the `limits` list.
- [x] P2. Keep Mac awake: a Home card, a palette command, a cup on the menu bar icon.
- [x] P3. Favorite AI sessions.
- [x] P4. Drag to reorder favorite simulators.
- [x] P5. Pin, label and add a note to local branches.
- [x] W1. Window mode setting and the main window.
- [x] W2. Right-click menu on the menu bar icon.
- [x] R1. Top-level comment and Request Changes.
- [x] R2. New thread on a diff line.
- [x] R3. Checks and pipeline jobs in the details.
- [x] S1. Create .devhub Starter.
- [x] S2. Switch project from the palette and with ⌃⌘1 to ⌃⌘9.
- [x] H1. Home "Today" card.
- [x] Q1. Simulator QA settings.
- [x] B1. Build log viewer.

## Step log

| Commit | Step | What it did |
|---|---|---|
| `54d15db` | P1 | `ClaudeUsageParser` reads `weekly_scoped` entries of the `limits` list after the flat keys; a flat value wins. Copied from the main DevHub `f38add6`. |
| `ee543d5` | P2 | `SleepPreventing` port (`IOKitSleepPreventer`, mock, spy), `KeepAwakeStore`, `KeepAwakeCard` on Home, the palette item, `StatusItemState.awake` (a cup). From the main DevHub `b53e0ad` and `de13128`. |
| `a6c5393` | P3 | `AISessionsStore.favoriteIDs` and `toggleFavorite` (key `ai.favorites`), a favorite stays in the project scope; `AISessionSectionsMapper` puts a Favorites section first; the row star and badge; favorites first in the palette. |
| `476b51a` | P4 | `FavoriteOrder`, `SimulatorsStore.favoriteOrder` and `moveFavorite(id:onto:)`, the sections mapper sorts favorites by the saved order, drag and drop on favorite rows. From the main DevHub `9dda0f0`. |
| `1de7a78` | — | `ShellRunnerIntegrationTests.cancellingStreamTerminatesTheProcess` allows 5 s: it failed under load with 1 s. |
| `da56372` | P5 | `BranchMark`, `BranchLabelPolicy`, `BranchMarksStore` (key `git.branchMarks.<project id>`), `BranchMarkDraft`, `BranchLabelMapper`, `BranchMarkEditor`, a Pinned section in Local, pin and label items in the row and its menu; pinned names join `protected:` of `BranchCleanupPolicy`. From the main DevHub `aaa5abd`. |
| `8116c33` | W1 | `WindowMode` and `AppSettings.windowMode`, `MainWindow`, `MainMenuBuilder`, `AppWindows` as `NSWindowDelegate` with `toggle()`, `show()`, `showWindow()`, `hideWindow()`, `applyWindowMode(_:)`; `WindowLayout.isWindowOpen`; `SettingsStore.showsDockIcon` and `onWindowModeChange`; `AppContainer` as the app delegate; the Window picker; `DEVHUB_WINDOW_MODE`. Checked on screen: the window is a Dock app (`Foreground`), the close button and File → Close Window hide it, `open` shows it again, the main menu has DevHub, File, Edit, Window, and the panel works after a switch back. |
| `25f1ad1` | W2 | `StatusMenuItem`, `StatusMenuMapper`, the right-click menu in `AppWindows.statusItemClicked`. Checked with a synthetic right click: the menu lists Show DevHub, the projects, Keep Mac Awake, Settings…, Quit DevHub. |
| `5884995` | R1 | `CodeHostRepository.comment` and `requestChanges`, `PullRequestPermissions.canRequestChanges` (GitHub: not the author), `PullRequestCommentBox` under the threads, drafts per request in `PullRequestDetailStore`; `DEVHUB_PULL_REQUEST`. Checked with a headless snapshot of the GitHub test repository: the box shows, Request Changes stays hidden on an own request. No comment was posted. |
| `65b49e9` | R2 | `PullRequestLineComment`, `CodeHostRepository.addLineComment` (GitHub review comment with `commit_id`, `line`, `side`; GitLab discussion with a `position` from `diff_refs`, `GlabDiffRefsParser`), `LineCommentDraft` in `PullRequestDetailStore`, `LineCommentComposer` under the line, a hover button and a context menu item on `DiffLine`. Checked by tests only: a headless snapshot cannot click a line. |
| `a51c3c5` | R3 | `PipelineJob.id` and `status`, `PullRequestDetails.jobs` (GitHub from the check rollup with `databaseId`, GitLab from every job of the head pipeline), `CodeHostRepository.jobLog` and `retryJob`, `GhClient.log` with `--allow-escape-sequences`, `JobLogTail`, `PipelineJobRowMapper`, `PipelineJobRow` with the log, Retry and the browser link. Checked: a headless snapshot of a request with a failed check; `gh api …/actions/jobs/<id>/logs` on the test repository. |
| `cc05fba` | S1 | `StarterConfigFacts`, `StarterConfigPolicy.projectJSON`, `ConfigRepository.createStarter` (refuses an existing `project.json`, `ConfigError.starterExists`), `ConfigStore.createStarter`, the button in Settings → Project config (the three buttons wrap in a `FlowLayout`). Checked by tests: the written file loads without issues. |
| `b1fdeb0` | S2 | `ProjectSwitchItem`, `ProjectSwitchMapper`, `ProjectShortcuts` (hidden buttons for ⌃⌘1 to ⌃⌘9), `ProjectShortcutModifier` on the project menu items, palette items "Switch to project …". Checked: a real ⌃⌘1 key press switched the project; a headless snapshot of the palette. |
| `36d2675` | H1 | `TodayTarget`, `TodayItemModel`, `TodayCardMapper` (review count, own requests with failed checks, finished worktrees, booted simulators), `TodayCard` on Home, `OpenPullRequestsStore.requests`, `AppActions.open(_:)` and `showPullRequests(scope:)`. Checked with a headless snapshot of the GitHub test repository. |
| `5cecd27` | Q1 | `SimulatorSetting` and its enums, the `SimulatorSettingsRepository` port (`SimctlSettingsRepository`, mock, spy), `SimulatorQAStore`, `SimulatorQAText`, `SimulatorQAPanel` and the row button. Checked: the simctl option names against `xcrun simctl … help`, a real status bar override, screenshot and clear on a booted simulator. The panel itself was checked by tests only. No video recording. |
| `51f3775` | B1 | `BuildIssue`, `BuildEvent.issue`, `BuildOutputParser.issue`, `BuildStore.issues` (at most 200, no repeats, cleared on a new build), `BuildIssuesMapper`, `BuildIssuesList` in the run bar, `AppActions.openFile(path:line:)`. Checked by parser tests with xcodebuild lines. |
| `fa97a37` | — | The snapshot recipe starts the app with `$PWD/$APP`, so its `pkill` matches. |
| `7ebf925` | — | STATUS, SPEC and this ADR describe the finished plan. |
| `6e77ee8` | — | `install.sh` to `/Applications/DevHub Generic.app` (copy first, then swap, optional local signing), `install-hooks.sh` and `auto-install.sh` from the main DevHub `04bd383` and `9ed2b1a`, `build.sh` with `DEVHUB_DERIVED_DATA` and the arch of the Mac. Checked: a commit on `main` installed and restarted DevHub Generic in the background; the main DevHub kept running. |
| `cf6d37c` | — | Step log row of `6e77ee8`. |
| `a025358` | — | AGENTS.md, STATUS decision 1, ADR 001 and the `update-docs` skill allow a push of `main` to the public remote. |
