# Status

Last updated: 2026-10-09 (M3, M5, M6)

## Stage

M0 (skeleton), M1 (shell runner, command log, Output panel), M2 (projects, config loader, scripts and actions), M3 (Git tab and Worktrees), M5 (Logs) and M6 (AI sessions and usage strip) are done. M4 (Simulators, Build & Run) is in progress. The remote builds clean and the app launches.

## Screens

| Screen | State | Notes |
|---|---|---|
| Panel shell (status item, panel, pin, hot key, header, tab bar, footer) | real | Checked with picture snapshots (`DEVHUB_SNAPSHOT`), not by hand clicks: status item click, right-click menu, outside-click close and the global shortcut still need a manual check |
| Output panel | real | Search, Show reads, Copy All, Clear, opens on failure, ⇧⌘O, 300 entries, 4 000 lines each |
| Home | real | Project card (branch, clean or N changes, ahead and behind, Finder, editor, Terminal, Repository), quick actions grid from `home.quickActions`, Scripts list with inputs, confirm, last run and result area, Recent, config problems, empty state with "Add project…". Build & Run and Run & Attach only navigate to Simulators and show a toast until M4. Checked with picture snapshots on a real Xcode workspace and on temporary projects, not by hand clicks |
| Git | real | Branch card, tags, pills, Local, Remote, History and Changes segments, diff, commit box, pull request line, rebase, merge and cherry-pick banner. Checked on a large real repository (read only) and on a throwaway repository with a bare origin (every write operation). `gh` and `glab` are not installed on this machine, so only the install hint was checked on screen; the JSON parsers were checked with sample output. Partial line staging is not in v1 |
| Worktrees | real | Create (local, remote, new), delete (clean, dirty, locked, DerivedData, branch), Clean Finished, Prune, include copy and bootstrap checked on the throwaway repository. DerivedData matching and removal checked with a fake folder in the real DerivedData root and with the real one for sizes. "Run on target" and "Use as build source" row actions wait for M4 |
| Simulators | partial | Real: the list of available simulators (`simctl list`), no sample banner. Missing: sections, favorites, boot, Build & Run bar, Stream logs button (M4) |
| Logs | real | Chips per simulator stream, searchable simulator list, level filter, search, Pause, Copy, Clear, redaction. Streams and levels are saved in `logs.streams`; streams restart on demand |
| AI | real | Checked with snapshots on 224 real sessions (176 Copilot, 48 Claude); 189 in the selected project. Resume was not pressed; the command text is in the button hint and the Recent list |
| Usage strip | real | Copilot shows premium requests with "N of M used". Claude shows 0% bars when the API returns null windows (Enterprise plan on this machine); see known gaps |
| Settings | partial | Real: global shortcut, terminal, editor, Dock icon, Projects (add, switch, detect again, open `.devhub`, create example, remove). Missing: launch at login, doctor. New: toggles for the usage strip and for Claude and Copilot usage percent in the menu bar |
| Custom tabs | planned | M7. The loader already decodes `tabs/*.json` into `ResolvedConfig.tabs`; nothing renders them yet |

States: planned, mock, real, partial (say what is missing).

## Decisions

Numbered. What, then why. A later session must not undo these without a new numbered entry that explains the change.

1. Own `NSStatusItem` and `NSPanel`, not `MenuBarExtra`. See spec 8.1.
2. No sandbox, ad-hoc signing, `LSUIElement`. Shell commands need it.
3. Config over code: no project name, path, bundle ID or branch in Swift.
4. The remote is always a working app: every commit builds clean and launches; every finished feature is pushed.
5. `FeatureRegistry` and `Feature` live in `Shell/FeatureRegistry.swift`, not in `Core`: a feature holds a view builder, and `Core` imports Foundation only.
6. `AppEvents` lives in `Shared` (stores in `Features` subscribe to it, and `App` is above them). Cases exist only when a second store needs them: `projectChanged`, `commandFailed`, `configChanged`, and `branchesChanged`, `worktreesChanged`, `simulatorsChanged` (posted by the `refresh` field and directive; no store listens yet).
7. `AppWindows` never imports `AppDependencies`. It gets a `makeContent` closure and passes a `PanelActions` value (environment `\.panelActions`) to the views.
8. `WindowLayout` is pure Foundation plus CoreGraphics types; `AppWindows` passes the screens' `visibleFrame` values in. Screens are matched by x only, because the menu bar lies outside `visibleFrame`.
9. A provider without a live type uses its mock in `Providers.live`, and its screen shows `SampleDataBanner`. Remove the banner when the screen goes live.
10. The shell settings store is `SettingsStore` (Shared, preferences with a loading guard). The Settings tab store is `SettingsTabStore`, because two files named `SettingsStore.swift` break the Swift build.
11. A failing `read` command (for example `git status` outside a repository) is recorded but does not open the Output panel and stays hidden unless "Show reads" is on. Every other failure opens the panel. A cancelled stream is recorded as "Cancelled", not as a failure.
12. `ShellRunner.run` is `nonisolated` so parallel runs do not queue on the actor; `stream` is actor-isolated. A non-zero exit code is a result, not a throw.
13. (Replaced by 15.) The project came from `DEVHUB_PROJECT_PATH`, the working folder or the home folder.
14. Debug aid: `DEVHUB_OPEN_PANEL=1`, `DEVHUB_TAB`, `DEVHUB_SNAPSHOT`, `DEVHUB_SNAPSHOT_DELAY`, `DEVHUB_PROJECT`, `DEVHUB_RUN_ACTION`, `DEVHUB_REQUEST_ACTION`, `DEVHUB_SEARCH`, `DEVHUB_SHOW_OUTPUT`, `DEVHUB_CREATE_EXAMPLE` (`App/DebugLaunch.swift`). M3, M5 and M6 added `DEVHUB_GIT_SEGMENT`, `DEVHUB_GIT_OPS` (`App/DebugGitOps.swift`), `DEVHUB_LOG_STREAM`, `DEVHUB_LOG_REDACT_CHECK`, `DEVHUB_AI_SCOPE`, `DEVHUB_AI_PROVIDER` and `DEVHUB_USAGE_EXPAND`; the `build-and-run` skill lists them all. It lets an agent look at the UI without a screen. `DEVHUB_TAB` and `DEVHUB_PROJECT` change saved preferences.
15. Projects are a saved list (`projects.list`) plus the selected path (`project.path`) in `AppPreferences`. `ProjectSession.project` is optional: with no project Home shows an empty state. `DEVHUB_PROJECT_PATH` and the working folder no longer choose a project. Switching posts `projectChanged`; `ConfigStore` reloads on it.
16. `ProjectConfig` is the schema of `project.json`; `ResolvedConfig` is the merged result (project config, actions, tabs, issues, layers). `project.json` merges field by field (deep) with the user layer winning; actions and tabs merge by `id`. A broken file is an issue with the file name and the reason; the rest loads. A broken `project.json` makes that layer's project config empty.
17. Script paths in `run.script` are relative to the `.devhub` folder of the layer (not the `actions` folder), so `scripts/x.sh` works from any action file. `DEVHUB_CONFIG_DIR` is that folder. Header script ids are `script:<file name without extension>`. `docs/extensions.md` says so.
18. The watcher uses `DispatchSource` on the three layer folders and their `actions`, `scripts` and `tabs` subfolders, plus a 2 second fingerprint check (names, sizes, modification dates). The check catches edits in place (a directory source does not fire for them) and folders that appear later. Reloads are debounced 300 ms.
19. Blocking file work (config reading, project detection) runs through `offMain { }`. With approachable concurrency a `nonisolated async` function runs on the caller's actor, so it would block the main actor.
20. The "Create .devhub example" content is embedded as Swift raw strings (`Core/Config/ExampleConfig.swift`, `ExampleScripts.swift`), not as bundle resources: strings always ship with the app and need no folder-structure handling in the synchronized folder (resources were not tried). Regenerate the Swift files when `docs/examples/devhub/` changes. The writer refuses when `<repo>/.devhub` exists.
21. One action prompt is open at a time (`ActionRunner.pending`). Each place that shows an action passes a `slot` string (for example `home.scripts:<id>`) and renders `ActionPrompt` when `runner.pending(in: slot)` is set. A row placement passes its item with `ActionItemContext`.
22. A directive error (`{"error": …}`) with exit code 0 marks the run failed, logs a failure, shows a red toast and opens the Output panel. A bad directive line is logged as a failure in Recent. `git remote get-url` is classified as a read.
23. `kind: command` projects and `build`, `run` commands are decoded but not executed yet (M4).
24. One git write path: `GitCommand` (Core, pure: arguments, environment, title) and `GitRepositoryProviding.run(_:at:)`. `GitExecutor` (Shared) runs a command, logs it in `ActivityLog` and shows a red toast on failure. Why: stores never build git arguments, so every write is logged and failures are visible.
25. `status` uses `git status --porcelain=v2 --branch -z --untracked-files=all`. Why: one command gives branch, upstream, ahead, behind and files. It replaces the v1 `-z` call of spec 8.4.
26. The selected checkout lives in `GitStore.selectedCheckout` and is mirrored to `ProjectSession.checkoutPath` and `checkoutBranch`. `session.activeCheckoutPath` and `session.activeBranch` fall back to the project folder and the main branch. Why: `ActionRunner` (Shared) cannot read `GitStore`.
27. Stores ignore events they post themselves (`isPosting`). `WorktreesStore` posts `worktreesChanged`, `GitStore` posts `branchesChanged`. A `projectChanged` for the same project keeps the loaded state. Why: the app posts it again after start, and a reload would flash the screen.
28. DerivedData size is measured with `du -sk` only when the Worktrees tab opens or after a change made there, never on Git refreshes. Folders match a worktree by the `WorkspacePath` of `info.plist` (longest path wins). Removing DerivedData does not measure sizes. Why: the DerivedData root can be very large.
29. Delete branch: a merged local branch (upstream is `origin/<same name>` and ahead is 0, plus `branch --merged`) is deleted with `-d` at once; otherwise an inline confirm runs `-D`. Deleting a worktree with the branch checkbox only uses `-d`; if git refuses, a toast says the branch was kept. A branch whose remote is gone can be refused by `-d` too. Why: no data loss without a confirm.
30. Stash Pop is plain `git stash pop` (a staged file comes back unstaged). Stash uses `--include-untracked`. Why: simple and predictable; untracked files must not be left behind.
31. The `Rebase on …` and `Update …` pill titles use the local name of the base (`origin/main` shows `main`). Update on a branch that is checked out in a worktree runs `git pull --ff-only` inside that worktree. Why: git refuses to move a branch that another worktree holds.
32. `GitCommand.checkRefFormat` and `verifyRef` are classified as reads (`check-ref-format` was added to the classifier). Why: an invalid branch name must not open the Output panel.
33. The Git header actions collapse to icons by `ActionBar` priority when the panel is narrow. With all pills and config actions the 720 pt panel shows Pull and Push with titles and the rest as icons. Why: buttons must never be cut.
34. Snapshot trap: SwiftUI does not redraw a panel that is covered by other windows, so a debug snapshot can show a state older than the model. Check results with the command line (git, files) as well as the picture.
35. `LogLine.Level` has five cases (debug, info, notice = Default, error, fault). The level control filters on the client; the stream always runs with `--level debug`. Why: changing the level then needs no restart and no lines are lost.
36. The log predicate uses the subsystem when it is not empty, else the process. Both come from config (`logs.subsystem`, `logs.process`) when a stream is created, and can be edited while the stream is stopped. Why: a subsystem is more exact than a process name.
37. A log stream needs a filter. With no process and no subsystem, the store reads `CFBundleExecutable` of the project app (bundle ID from the effective project). If that fails, the stream shows an error and does not start. Why: an unfiltered stream floods the panel with system lines.
38. Redaction runs in `LogLineParser`, so a line is masked before it leaves the parser and before it reaches the store. Why: no secret can reach memory, the list or a copy.
39. `SimulatorProviding` has `executableName(simulatorID:bundleID:)`. `SimulatorInfo.isFavorite` is always false until M4 adds favorites.
40. Sessions are indexed by `AISessionIndex` (an actor). Each session file is parsed once and cached by modification date (Copilot: newest of `events.jsonl` and `workspace.yaml`). Files are memory mapped and scanned by line prefix with `memchr`; a Copilot `events.jsonl` is scanned from the start for the first prompt and from the end for the last prompt. Why: hundreds of large session files must not slow the panel.
41. Session date: Claude uses the file modification date, Copilot uses `updated_at`.
42. The AI provider returns all sessions; scope and provider filters are applied in `AIStore`. Scope "This project" matches a `cwd` equal to or under the project folder. Why: switching a filter does not read files again.
43. Resume calls `WorkspaceActing.runInTerminal(command: "<tool> --resume <id>", at: cwd)`. Session ids are checked to letters, digits, `-` and `_` before use. Why: the id ends up in a shell command.
44. Usage rows with no login (no keychain item, no file, no `gh`) are hidden. An expired or refused login shows the inline error with Retry. The Claude token is never refreshed. Why: a missing login is normal, and refreshing a token could break the login of the Claude app.
45. Claude `five_hour` or `seven_day` with a `null` value is currently shown as 0% ("No active window"); see known gaps. Other null keys are ignored. Unknown fields with `utilization` and `resets_at` are ignored unless they start with `seven_day_` (then they are shown).
46. A usage refresh runs in its own unstructured task. Why: a SwiftUI `.task` restart must not cancel the request.
47. `WindowLayout.isShown` (set by `AppWindows` on show and close) tells the poller that the panel is open. The poll tick is 30 s; a refresh happens when data is older than 5 minutes, only while the panel is shown or a menu bar percent is on. Why: no network traffic while the panel is closed.
48. Menu bar percent has two toggles (Claude session, Copilot premium). `MenuBarUsage` observes `UsageStore.menuBarText` and calls `AppWindows.setStatusTitle`. Not checked on a real screen.
49. `CommandLog` does not open the Output panel for a failed `secret` command, and `gh auth token` is classified as secret. Why: a missing login is normal, and the output must stay hidden.

## Next steps

1. M4: Simulators tab UI (sections, favorites, Stream logs button calling `LogsStore.startStream(udid:name:)` then `navigator.show("logs")`), Build & Run (wire `builtin.buildRun` and `builtin.runAttach` in `ActionRunner.performBuiltin`, the `simulator` input picker, the `when.simulator` condition, `DEVHUB_APP_PATH`, `kind: command`).
2. M4: "Run on target" in Local and Remote branch rows and worktree rows, "Use as build source" (`WorktreesStore.setBuildSource(_:)` exists), and `build.run(branch:)` through `WorktreesStore.checkoutPath(forBranch:)`. That call returns the main checkout, the worktree that has the branch, or creates one; it throws `WorktreeFailure`.
3. M7 custom tabs and the palette from `ResolvedConfig.tabs`. Add a palette entry "resume session" (spec 4.3).
4. Fix the known gaps below, first the loading states and the usage strip.
5. Manual check on a real screen: status item, right-click menu, outside-click close, Esc, ⌘1 to ⌘9, ⌘F, ⇧⌘O, the global shortcut, the checkout picker popover, hover actions, overflow menus, inline confirms, the diff scroll, the menu bar usage title and the pinned window.
6. Notifications for the `notify` directive (it is logged for now). Launch at login (`SMAppService`).
7. `refresh: logs` in `ActionRunner.applyRefresh` does nothing yet.
8. Copilot `unlimited` and free plans were not seen on this machine; the parser handles them by shape only.

## Known gaps

- The status item, the global shortcut and the right-click menu are written but were not exercised with real clicks.
- The Output panel opens at a fixed height of 220 points.
- Hints are checked only by build, not on screen.
- `Providers.live` still uses the mock for build.
- Prompts, hover hints, the header project picker and the folder picker were checked by build and by code, not by clicking: snapshots cannot click.
- Detected schemes come from shared `.xcscheme` files of the container and of the Xcode projects it references outside `Pods/`. User schemes are not read.
- The Home reads `git remote get-url` on every refresh (a hidden read command); two refreshes run on each panel open.
- Right-to-left and VoiceOver are not looked at.
- The Git tab shows "No commits yet" and "No results" while data is still loading on a large repository. It should show a loading state.
- The base branch itself (for example `dev`) gets a "merged" tag in the Local list. It should not.
- The usage strip shows 0% bars when Claude returns null `five_hour` and `seven_day` (Enterprise plan). It should hide the bars and say there is no active window.
- The Copilot bar once showed 100% without the "N of M used" detail. The parser (`CopilotUsageParser`) reads `entitlement` and `remaining` and builds the detail; check again with a real response that has both fields.
- "Run on target" and "Use as build source" are not in the rows yet (M4).
- A branch build source needs an existing worktree checked out for that branch; `BuildStore` does not create one.
