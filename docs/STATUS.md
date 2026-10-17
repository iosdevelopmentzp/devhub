# Status

Last updated: 2026-10-17 (rewrite, milestone M2)

## Stage

The app is being rewritten on the package architecture of the main DevHub. The plan and its step log are in `docs/adr/001-port-from-main-devhub.md` (milestones M0 to M8).

- M0 done: local git repository, anonymity check, the plan as ADR 001.
- M1 done: the package `Packages/DevHubKit` (seven modules, about 1,480 tests) is the app. Slack commands and the session log reader are gone. The first generic app is in `legacy/` as the port source and is not built.
- M2 done: the `.devhub/` config system inside the modules (ADR 002): Home quick actions and scripts, config problems, hot reload, placements in the Git header, branch, worktree and simulator rows, the run bar and the Logs toolbar. About 1,570 tests.
- Next: M3, Git from config (ADR 001 section 7.3): the remote name, the base branch, protected branches, the ticket pattern, the worktree folder, include list and bootstrap.

## Screens

| Screen | State | Notes |
|---|---|---|
| Panel shell (status item, panel, pin, hot key, header, tab bar, footer, Output panel) | real | From the package. Checked with headless snapshots. With no project the panel shows "No project yet" and an Add Project button |
| Home | real | Project card, quick actions from `home.quickActions`, Scripts from `.devhub/scripts` with inputs, confirm, result area and last run, config problems. Checked with headless snapshots on a throwaway repository with the example `.devhub` folder: a script run, the footer progress, the Output panel and a hot reload of `project.json` |
| Git | real | Local, Remote, History, Reflog, Changes, stash, commit box, switch with local changes, request line. The remote is `git.remote` (default `origin`); the base branch is `git.baseBranch`, else `<remote>/HEAD`, else `<remote>/main`. Checked with a headless snapshot on a throwaway repository with a bare remote called `upstream`. Config actions: `git.pills` in the header, `git.branchRow` in the branch context menu |
| GitLab | real | Merge requests through `glab` only. Becomes the Pull Requests tab with GitHub first in M4 |
| Worktrees | real | Config actions in the row context menu (`worktrees.row`). Folder, include list and bootstrap script from `git.worktrees`. Checked with a headless snapshot: a worktree in `.worktrees/` shows "needs bootstrap" when `Pods` exists only in the main checkout |
| Simulators, Build & Run | real | From the package. Config actions in the run bar (`simulators.runBar`) and in the row overflow menu (`simulators.row`). Launch profiles and `kind: command` projects come in M5 |
| Device identity | hidden | No project has an identity config: the presets are gone. Launch identities from config come in M6 |
| Logs | real | One stream at a time. Config actions in the toolbar (`logs.toolbar`). Chips for several streams come in M5 |
| Network | partial | Shows the requests that pass through the DevHub mock server only. The session log source is gone. The base URL variable and upstreams from config come in M6 |
| Claude | real | Claude sessions and usage. Copilot comes in M5 |
| Settings | real | From the package. Doctor and launch at login come in M7 |
| Custom tabs, command palette | planned | M7 |

States: planned, mock, real, partial (say what is missing), hidden.

## Decisions

Numbered. What, then why. A later session must not undo these without a new numbered entry that explains the change.

1. The code is never pushed. The repository has no remote. Why: the owner decided so. The GitHub account on this machine is used only for the playground repository that tests the pull request features.
2. Own `NSStatusItem` and `NSPanel`, not `MenuBarExtra`. No sandbox, ad-hoc signing, `LSUIElement`. Why: shell commands need it, and the panel needs its own position, size and close rules.
3. Config over code: no project name, path, bundle ID, host or branch name in Swift. `Scripts/check-anonymous.sh` enforces the names; `.claude/rules/anonymity.md` lists the sample vocabulary.
4. The owner's own words live in `~/.devhub/anonymity-denylist.txt`, outside the repository. Why: the list itself would name the projects.
5. The package architecture of the main DevHub is the base: modules `Domain`, `Data`, `Mocks`, `UI`, `Presentation`, `Composition`, `TestSupport`, Swift 6, Swift Testing with spies. `docs/ARCHITECTURE.md` is the contract.
6. Common branch names (`main`, `master`, `develop`, `dev`) are not project names and may appear in tests and defaults. The remote comes from `git.remote` (`GitSettingsPolicy.defaultRemote` is `origin`), and every git command, `BranchName` and policy takes the remote name as a parameter.
7. The first launch has no project. `ProjectSession.selectedProject` falls back to `Project.none` and `RootView` shows `NoProjectState` instead of a tab. Why: the main app had a fixed default project, and a generic app cannot know one.
8. The Network tab lists only the exchanges of the DevHub mock server. Why: the session log was the log format of one app. `NetworkStore` keeps selection, filter, pause and clear over the server exchanges.
9. Debug launch switches live in `DevHubComposition/Debug/DebugLaunch.swift` and are compiled in Debug builds only. Today: `DEVHUB_PROJECT`, `DEVHUB_OPEN_PANEL`, `DEVHUB_TAB`, `DEVHUB_SNAPSHOT`, `DEVHUB_SNAPSHOT_DELAY`, `DEVHUB_RUN_ACTION` (comma-separated action ids, run with default inputs), `DEVHUB_REQUEST_ACTION` (one id, opens its prompt), `DEVHUB_SHOW_OUTPUT`. `DEVHUB_PROJECT`, `DEVHUB_TAB` and `DEVHUB_SHOW_OUTPUT` change saved preferences. The rest of the switches from `legacy/App/DebugLaunch*.swift` come with the features they drive.
10. Snapshot trap: SwiftUI does not redraw a panel that is covered by other windows, and `cacheDisplay` does not draw some controls (a prominent button looks empty). Check results on the command line as well as in the picture.
11. The scripts stop only the build of this repository, by its executable path. Why: another app with the same name (`DevHub`) can run on the same machine.
12. The app keeps the bundle ID `devteams.DevHub` of the first generic app, so it reads and writes the same preferences domain.
13. "Copy for Slack" is "Copy Link with Title" (`RequestLinkText`): the reference, the title and the link.
14. `waitUntil` waits 10 s by default, not 2 s. Why: right after a build, about 25 store tests timed out on the busy main actor while the same tests passed alone.
15. The `.devhub/` config models are `Codable` Domain types (`Models/Config/`), the one exception to "no `Decodable` Domain model" (`docs/ARCHITECTURE.md` section 5). `ExampleConfig.files` is generated from `docs/examples/devhub/` by `Scripts/generate-example-config.sh`; run it after every change there.
16. After a change to an enum in a lower module (for example a new `Tint` case), remove `Packages/DevHubKit/.build` before `Scripts/test.sh`. Why: the incremental test build once kept old object files, and the tests read wrong enum values.
17. A config action in a row placement shows its inputs and confirmation under that row. The screen draws the prompt (`ConfigActionsStore.pending(in:)` with the slot `<placement>:<row id>`), the row gets only `configActions` in its model and an `onConfigAction` closure. Why: a row reads no store but `Toaster` and `AppActions`.

## Next steps

1. M3 (ADR 001 section 7.3): `git.remote` instead of the literal `origin`, `git.baseBranch`, protected branch lists, `git.commitPrefix` for the ticket chip and the commit box, `git.worktrees.*` instead of `init.sh`, `.worktreeinclude` and `.claude/worktrees`, "Open in Editor" on file rows, the `DEVHUB_GIT_OPS` debug script.
2. Rewrite the skills that still describe the first generic app (`add-feature`, `providers-and-shell`, `build-and-run`, `panel-window`, `ui-components`, `xcode-toolchain`, `update-docs`) when the milestone that touches their area lands.
3. `docs/SPEC.md` still describes the first generic app; M8 refreshes it.

## Known gaps

- Settings with no project: the Settings tab also shows "No project yet" until a project is added. Adding a project works from that screen and from the header menu.
- `pullRequests.row` and `network.toolbar` from ADR 001 Appendix B.3 are not placements yet. `pullRequests.row` comes with the Pull Requests tab in M4. `network.toolbar` is not in `docs/extensions.md`; adding it changes the schema, so it waits for the owner.
- The context menus of rows were checked by tests only: a headless snapshot does not open a menu.
- The identity panel is hidden for every project (no identity config) until M6.
- The status item click, the global shortcut and the right-click menu were not exercised with real clicks in this session; only headless snapshots.
