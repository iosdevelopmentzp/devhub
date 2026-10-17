# Status

Last updated: 2026-10-17 (rewrite, milestone M1)

## Stage

The app is being rewritten on the package architecture of the main DevHub. The plan and its step log are in `docs/adr/001-port-from-main-devhub.md` (milestones M0 to M8).

- M0 done: local git repository, anonymity check, the plan as ADR 001.
- M1 done: the package `Packages/DevHubKit` (seven modules, about 1,480 tests) is the app. Slack commands and the session log reader are gone. The first generic app is in `legacy/` as the port source and is not built.
- Next: M2, the `.devhub/` config system inside the modules.

## Screens

| Screen | State | Notes |
|---|---|---|
| Panel shell (status item, panel, pin, hot key, header, tab bar, footer, Output panel) | real | From the package. Checked with headless snapshots. With no project the panel shows "No project yet" and an Add Project button |
| Home | partial | Project card and quick actions are real. The Scripts list still shows sample scripts (`MockData.scripts`) until M2 brings the `.devhub/` scripts |
| Git | real | Local, Remote, History, Reflog, Changes, stash, commit box, switch with local changes, request line. The base branch falls back to `origin/main`; config comes in M3 |
| GitLab | real | Merge requests through `glab` only. Becomes the Pull Requests tab with GitHub first in M4 |
| Worktrees | real | The worktree folder, include list and bootstrap script still follow the old fixed conventions until M3 |
| Simulators, Build & Run | real | From the package. Launch profiles and `kind: command` projects come in M5 |
| Device identity | hidden | No project has an identity config: the presets are gone. Launch identities from config come in M6 |
| Logs | real | One stream at a time. Chips for several streams come in M5 |
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
6. Common branch names (`main`, `master`, `develop`, `dev`) are not project names and may appear in tests and defaults. The base branch fallback is `origin/main` (`BranchName.defaultBaseRef`) until M3 reads `git.baseBranch`.
7. The first launch has no project. `ProjectSession.selectedProject` falls back to `Project.none` and `RootView` shows `NoProjectState` instead of a tab. Why: the main app had a fixed default project, and a generic app cannot know one.
8. The Network tab lists only the exchanges of the DevHub mock server. Why: the session log was the log format of one app. `NetworkStore` keeps selection, filter, pause and clear over the server exchanges.
9. Debug launch switches live in `DevHubComposition/Debug/DebugLaunch.swift` and are compiled in Debug builds only. Today: `DEVHUB_PROJECT`, `DEVHUB_OPEN_PANEL`, `DEVHUB_TAB`, `DEVHUB_SNAPSHOT`, `DEVHUB_SNAPSHOT_DELAY`. `DEVHUB_PROJECT` and `DEVHUB_TAB` change saved preferences. The rest of the switches from `legacy/App/DebugLaunch*.swift` come with the features they drive.
10. Snapshot trap: SwiftUI does not redraw a panel that is covered by other windows, and `cacheDisplay` does not draw some controls (a prominent button looks empty). Check results on the command line as well as in the picture.
11. The scripts stop only the build of this repository, by its executable path. Why: another app with the same name (`DevHub`) can run on the same machine.
12. The app keeps the bundle ID `devteams.DevHub` of the first generic app, so it reads and writes the same preferences domain.
13. "Copy for Slack" is "Copy Link with Title" (`RequestLinkText`): the reference, the title and the link.
14. `waitUntil` waits 10 s by default, not 2 s. Why: right after a build, about 25 store tests timed out on the busy main actor while the same tests passed alone.

## Next steps

1. M2: the config system (Appendix B of ADR 001, steps 1 to 5): Domain config models, `ConfigMergePolicy`, `FileConfigRepository` with the watcher, `ConfigStore`, `ConfigActionsStore`, placements, the example writer, scripts from `.devhub/scripts` on Home instead of `MockData.scripts`.
2. Rewrite the skills that still describe the first generic app (`add-feature`, `extensions`, `providers-and-shell`, `build-and-run`, `panel-window`, `ui-components`, `xcode-toolchain`, `update-docs`) when the milestone that touches their area lands.
3. `docs/SPEC.md` still describes the first generic app; M8 refreshes it.

## Known gaps

- Settings with no project: the Settings tab also shows "No project yet" until a project is added. Adding a project works from that screen and from the header menu.
- The Home Scripts section shows sample scripts.
- The identity panel is hidden for every project (no identity config) until M6.
- The status item click, the global shortcut and the right-click menu were not exercised with real clicks in this session; only headless snapshots.
