# Status

Last updated: 2026-10-18 (rewrite, milestone M4)

## Stage

The app is being rewritten on the package architecture of the main DevHub. The plan and its step log are in `docs/adr/001-port-from-main-devhub.md` (milestones M0 to M8).

- M0 done: local git repository, anonymity check, the plan as ADR 001.
- M1 done: the package `Packages/DevHubKit` (seven modules, about 1,480 tests) is the app. Slack commands and the session log reader are gone. The first generic app is in `legacy/` as the port source and is not built.
- M2 done: the `.devhub/` config system inside the modules (ADR 002): Home quick actions and scripts, config problems, hot reload, placements in the Git header, branch, worktree and simulator rows, the run bar and the Logs toolbar. About 1,570 tests.
- M3 done: Git from config. `git.remote`, `git.baseBranch`, `git.protectedBranches`, `git.commitPrefix`, `git.ticketURL`, `git.worktrees.*`; "Open in Editor" on file rows; `DEVHUB_GIT_OPS`. Checked on a throwaway repository with a bare remote called `upstream`. About 1,600 tests.
- M4 done: one code host port for GitHub (`gh`) and GitLab (`glab`), ADR 003. The Pull Requests tab, the Git status line and branch tags use the words of the host. `git.host.*`, `git.pullRequests.*`, `ai.reviewCommand`, the `pullRequests.row` placement, `when.host` and the `pullRequests` refresh target. Checked on a private GitHub test repository: the list in four scopes, details with a thread, files, draft and ready, update branch, merge with branch removal, create with labels, reply, resolve, re-run and cancel a check run. About 1,650 tests.
- M5 done: Build & Run from config. `xcode.*` in the run bar and in `xcodebuild`, launch profiles (environment, arguments, `defaults` in the app or group container, clean install), `kind: command` projects, the `simulators.statusScript` line, deep link schemes from the installed app, log chips with one stream per simulator, Copilot CLI sessions and Copilot usage. Checked on a sample app: the main checkout, a worktree, a branch without a checkout, both profiles, a command project, two log streams at once, the status line, the AI tab with Copilot and Claude sessions and the usage strip with both providers. About 1,715 tests.
- M6 in progress: launch identities and the network config (ADR 001 sections 7.6, 7.7 and Appendix A). Done: the config keys, the `state` directive, launch identities in Build & Run, the identity panel and the run bar, and the mock server with profile upstreams and `network.baseURLVariable`. Next: `network.mocksFolder`, the empty states of the Network tab and the example config.

## Screens

| Screen | State | Notes |
|---|---|---|
| Panel shell (status item, panel, pin, hot key, header, tab bar, footer, Output panel) | real | From the package. Checked with headless snapshots. With no project the panel shows "No project yet" and an Add Project button |
| Home | real | Project card, quick actions from `home.quickActions`, Scripts from `.devhub/scripts` with inputs, confirm, result area and last run, config problems. Checked with headless snapshots on a throwaway repository with the example `.devhub` folder: a script run, the footer progress, the Output panel and a hot reload of `project.json` |
| Git | real | Local, Remote, History, Reflog, Changes, stash, commit box, switch with local changes, request line. The remote is `git.remote` (default `origin`); the base branch is `git.baseBranch`, else `<remote>/HEAD`, else `<remote>/main`. Checked with a headless snapshot on a throwaway repository with a bare remote called `upstream`. Config actions: `git.pills` in the header, `git.branchRow` in the branch context menu |
| Pull Requests | real | GitHub through `gh`, GitLab through `glab`, chosen by the remote or `git.host.kind`. Title, `#`/`!`, checks or pipeline and the open-in-browser words follow the host. Config actions in the row menus (`pullRequests.row`). The toolbar wraps on a narrow panel. Checked with headless snapshots and `gh` on a private GitHub test repository |
| Worktrees | real | Config actions in the row context menu (`worktrees.row`). Folder, include list and bootstrap script from `git.worktrees`. Checked with a headless snapshot: a worktree in `.worktrees/` shows "needs bootstrap" when `Pods` exists only in the main checkout |
| Simulators, Build & Run | real | Config actions in the run bar (`simulators.runBar`) and in the row overflow menu (`simulators.row`). `xcode.*`, launch profiles, `kind: command` projects, the `simulators.statusScript` line under rows and the run bar target, deep link schemes from the installed app. Checked with `DEVHUB_BUILD_RUN` on a sample app and a command project |
| Device identity | real | Shown when `launch.identity` is set. ID, alias, saved IDs, clean install when the ID changes, the `state` report of the status script. Checked with `DEVHUB_BUILD_RUN` and `DEVHUB_LAUNCH_ID` on a sample app |
| Logs | real | One chip and one stream per simulator, each with its own process, subsystem, level and pause state; saved. `logs.process` and `logs.subsystem` give the defaults of a new stream. Config actions in the toolbar (`logs.toolbar`). Checked with `DEVHUB_LOG_STREAMS` on two booted simulators |
| Network | partial | Shows the requests that pass through the DevHub mock server only. The session log source is gone. The upstream comes from the launch profile and the URL goes into `network.baseURLVariable`. `network.mocksFolder` and the empty states come next in M6 |
| AI | real | Copilot CLI and Claude Code sessions with a provider and a scope filter and Resume. The usage strip shows Claude and, when logged in, Copilot. Checked with headless snapshots on the real session folders |
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
9. Debug launch switches live in `DevHubComposition/Debug/DebugLaunch.swift` and are compiled in Debug builds only. Today: `DEVHUB_PROJECT`, `DEVHUB_OPEN_PANEL`, `DEVHUB_TAB`, `DEVHUB_SNAPSHOT`, `DEVHUB_SNAPSHOT_DELAY`, `DEVHUB_RUN_ACTION` (comma-separated action ids, run with default inputs), `DEVHUB_REQUEST_ACTION` (one id, opens its prompt), `DEVHUB_SHOW_OUTPUT`, `DEVHUB_GIT_OPS` (comma-separated steps such as `fetch,stage:a.txt,commit:Message,push,wt-create:feature/x,switch:topic,delete-branch:topic`; each step waits until the stores are idle; the list is in `PresentationAssembly+DebugGitOps.swift`). `DEVHUB_PROJECT`, `DEVHUB_TAB` and `DEVHUB_SHOW_OUTPUT` change saved preferences. The rest of the switches from `legacy/App/DebugLaunch*.swift` come with the features they drive.
10. Snapshot trap: SwiftUI does not redraw a panel that is covered by other windows, and `cacheDisplay` does not draw some controls (a prominent button looks empty). Check results on the command line as well as in the picture.
11. The scripts stop only the build of this repository, by its executable path. Why: another app with the same name (`DevHub`) can run on the same machine.
12. The app keeps the bundle ID `devteams.DevHub` of the first generic app, so it reads and writes the same preferences domain.
13. "Copy for Slack" is "Copy Link with Title" (`RequestLinkText`): the reference, the title and the link.
14. `waitUntil` waits 10 s by default, not 2 s. Why: right after a build, about 25 store tests timed out on the busy main actor while the same tests passed alone.
15. The `.devhub/` config models are `Codable` Domain types (`Models/Config/`), the one exception to "no `Decodable` Domain model" (`docs/ARCHITECTURE.md` section 5). `ExampleConfig.files` is generated from `docs/examples/devhub/` by `Scripts/generate-example-config.sh`; run it after every change there.
16. After a change to an enum in a lower module (for example a new `Tint` case), remove `Packages/DevHubKit/.build` before `Scripts/test.sh`. Why: the incremental test build once kept old object files, and the tests read wrong enum values.
17. A config action in a row placement shows its inputs and confirmation under that row. The screen draws the prompt (`ConfigActionsStore.pending(in:)` with the slot `<placement>:<row id>`), the row gets only `configActions` in its model and an `onConfigAction` closure. Why: a row reads no store but `Toaster` and `AppActions`.
18. A remote whose host name contains neither `github` nor `gitlab` counts as GitLab unless `git.host.kind` says `github`. Why: a self-hosted GitLab on a company domain is the common case; GitHub Enterprise users set the kind once. The ADR idea to ask `gh auth status` was dropped: it would make the choice depend on the machine.

19. The code host types use pull request words: `PullRequestSummary`, `CodeHostRepository`, `PullRequestsStore`, `ReviewThread`, `MergeReadiness`, `CheckStatus`, the tab id `pullRequests`. The fields keep their names (`iid`, `pipeline`, `detailedStatus`), and the GitLab GraphQL strings keep the GitLab names (`MergeRequestState`, `mergeRequests`). Why: a field rename touches every mapper and test for no change in behaviour, and the GraphQL names belong to GitLab.
20. `.gitignore` ignores only the top-level `/build/` folder. Why: on the case-insensitive macOS file system `build/` also matched every `Build/` source folder, and the Build feature was missing from the commits.
21. UI words for the code host come from `CodeHostWords` (`Shared/`): "Pull Requests" and `#12` for GitHub, "Merge Requests" and `!12` for GitLab, "checks" or "pipeline". Mappers take `words:`; views and rows read `@Environment(\.codeHostWords)`, which `CodeHostRemote` sets after the first read of the remote. Before that the words are neutral ("Pull Requests", "Open in Browser"). Why: one place for the vocabulary, and rows need no new store.
22. Actions that a host or a repository does not allow are hidden, not shown with an error: `PullRequestPermissions.canRevokeApproval` (GitHub: write access) and `canSetAutoMerge` (GitHub: write access and `autoMergeAllowed` on the repository).
23. A `kind: command` project runs `build.command`, then `run.command`, in the checkout of the run bar, with the action variables (`DEVHUB_SIMULATOR_UDID`, `DEVHUB_BRANCH`, …). Both commands may print `@devhub {"app": "<path>"}`; a relative path is read from the checkout. A script file without the executable bit runs through `/bin/zsh`. Run & Attach stays off for these projects. Why: the app path is known only after the build, and a fresh clone often loses the executable bit.
24. Deep link schemes come from `CFBundleURLTypes` in the `Info.plist` of the app installed on the simulator, not from a `simulators.deepLinks` config key (ADR 001 section 7.5). Why: the app already declares its schemes, and a new key would change the config schema.
25. The AI tab does not check that `copilot` or `claude` is installed before Resume. Why: Resume runs in the terminal with the PATH of the user; the app's own PATH misses folders such as `~/.local/bin`, so a check from the app would hide working sessions. The Doctor section (M7) shows missing tools.
26. The Copilot token comes from `gh auth token` first and from the `copilot-cli` keychain item second. The keychain read stops after 10 s and is not tried again until the app restarts. Why: macOS can ask the user to allow `/usr/bin/security` to read that item; a background refresh every 5 minutes must not keep that dialog open or show it again and again.
27. The M6 config keys follow ADR 001 Appendix A, approved by the owner on 2026-10-18: `launch.identity.*`, `launch.profiles[].storage`, `upstream` and `production`, `network.baseURLVariable` and `network.mocksFolder`, and the `state` directive of the status script.
28. A launch identity is a plan, not stored state: `LaunchPlan` joins the profile, `launch.identity` and the chosen ID, and every launch (Build & Run, Launch, Apply & Relaunch) goes through `simulators.launch` with its environment and arguments. The result is a `LaunchRecord` (bundle ID, profile, ID, mock server URL) that `IdentityStore` saves per simulator under `simulators.launchSettings`. The old key `simulators.identity` is not migrated. Why: the old settings held an environment name and a hard-coded device ID format that no longer exist; a reset costs one choice per simulator.
29. The clean install rule (`CleanInstallPolicy`): with a chosen ID, reinstall when the actual ID (the `state` report, else the last ID DevHub set) differs. With no chosen ID, reinstall only when the actual ID is one that DevHub set or saved. Why: the app's own ID must not cause a reinstall on every Build & Run; that would lose the session each time.
30. The bundle ID of the identity panel and the mock server is the one of the last launch on that simulator when the project config knows it, else the effective bundle ID of the project. Why: `IdentityStore` sits below `BuildStore` and cannot read the run bar scheme; the last launch records what Build & Run really installed.
## Next steps

1. M6 (ADR 001 sections 7.6 and 7.7): launch identities from config and the `state` directive, the network base URL variable and upstreams from config.
2. Rewrite the skills that still describe the first generic app (`add-feature`, `providers-and-shell`, `panel-window`, `ui-components`, `xcode-toolchain`, `update-docs`) when the milestone that touches their area lands.
3. `docs/SPEC.md` still describes the first generic app; M8 refreshes it.

## Known gaps

- Settings with no project: the Settings tab also shows "No project yet" until a project is added. Adding a project works from that screen and from the header menu.
- `xcrun simctl boot` on a booted simulator shows a red row in the Output panel (exit code 149). The run goes on: the repository accepts that code, but the command log does not know it.
- `network.toolbar` from ADR 001 Appendix B.3 is not a placement yet. It is not in `docs/extensions.md`; adding it changes the schema, so it waits for the owner.
- Auto-merge on GitHub was not seen working: the test repository is private on a free plan, which has no branch protection and no auto-merge. The action stays hidden there (`autoMergeAllowed` is false).
- The GitLab flows were not clicked through after the M4 rename: that needs a GitLab host of the owner. The `glab` code and its tests did not change in behaviour.
- The Doctor rows for `gh` and `glab` come with the Doctor section in M7.
- The context menus of rows were checked by tests only: a headless snapshot does not open a menu.
- With `xcode.bundleIDs` per scheme, the identity panel reads the app of the effective scheme until the first launch from DevHub on that simulator (decision 30).
- Launch & Attach in a simulator row needs `launch.identity`: without it DevHub does not read whether the app is installed.
- The first read of the AI tab takes several seconds when `~/.claude/projects` and `~/.copilot/session-state` hold about 1 GB; later reads use the cache.
- The messaging panel and Resume in the AI tab were checked by tests only: a headless snapshot cannot open the panel or click a button.
- The status item click, the global shortcut and the right-click menu were not exercised with real clicks in this session; only headless snapshots.
