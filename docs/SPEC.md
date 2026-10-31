# DevHub product specification

This document describes what DevHub does today and why. It covers the panel, every tab, the config system, the technical rules that the code depends on, and a checklist to test the app by hand.

Other documents give the details:

| Document | Content |
|---|---|
| `docs/features/<tab>.md` | one page per tab: every action, the command it runs, the config it reads, the limits |
| `docs/extensions.md` | the full `.devhub/` config schema |
| `docs/ARCHITECTURE.md` | the module contract of the Swift package |
| `docs/STATUS.md` | what is real per screen, numbered decisions, known gaps |
| `docs/adr/` | design decisions: the rewrite plan (001), the config system (002), code hosts (003), launch identities and network (004) |

When this document and the code disagree, the code is right. Fix this document in the same commit.

---

## 1. Purpose and users

### 1.1 What DevHub is

DevHub is a personal macOS menu bar app for daily iOS development work across many repositories. One click on the menu bar icon opens a panel. The panel has tabs for git, worktrees, pull requests, simulators, Build & Run, app logs, a network mock server and AI sessions.

The core is generic. Swift code never names a project, a path, a bundle ID, a host or a branch. Each project describes itself in `.devhub/` config files: how it builds, its launch profiles, its quick actions, its scripts and its own tabs.

### 1.2 Users

1. An iOS developer who works on several repositories and many branches at the same time.
2. A team that shares one `.devhub/` folder in the repository, so every member gets the same actions and scripts.
3. A QA engineer or a developer who needs to run the app with a given device ID, environment or mocked server answer.

### 1.3 Principles

1. **Config over code.** A difference between projects goes into `.devhub/`, never into Swift.
2. **Every external command is visible.** Every process runs through one `ShellRunner`. Each run appears in the Output panel with its folder, output, duration and exit code.
3. **The user's branch never changes without a request.** A build of another branch uses a worktree. Pull and update use fast-forward only.
4. **Secrets stay in memory.** A token is read for one request and then dropped. The output of `security` and `gh auth token` is never recorded. Log lines are masked before DevHub keeps them.
5. **Search in every list.** The header search filters the list of the current tab. Long pickers have a search field.
6. **Fast open.** The panel opens at once with the last state and refreshes in the background.
7. **A missing tool does not break the app.** When `gh`, `glab`, `copilot` or `claude` is missing or not logged in, the feature shows what to install or run. The other tabs work.
8. **Every failure is visible.** A failed command opens the Output panel. A failed action adds a red line to the Recent list on Home. No error is caught without a message.

### 1.4 Non-goals

- Physical devices (`devicectl`).
- App Store distribution, notarization or the App Sandbox. The app uses ad-hoc signing. A sandbox would block `git`, `xcrun` and `xcodebuild`.
- Chat integrations. A project that needs one adds an action with a script.
- An AI chat inside the app. The AI tab lists sessions, resumes them and shows quotas.
- A dark theme. The panel always uses the light appearance.

---

## 2. The panel shell

Details: `docs/features/output.md` (Output panel) and `docs/features/palette.md` (command palette).

### 2.1 Status item and menu bar icon

- DevHub has no Dock icon by default (`LSUIElement`). Settings can show one, and the "Normal window" mode always has one.
- The status item shows a hammer icon. A left click opens or closes the panel (or shows and hides the window in window mode). A right click opens a menu: Show DevHub, the projects, Keep Mac Awake, Settings…, Quit DevHub.
- While Keep Mac awake is on and nothing else needs the icon, it shows a cup (`cup.and.saucer.fill`).
- The icon shows the build state:

  | State | Icon |
  |---|---|
  | idle | `hammer.fill` |
  | a build runs | `hammer.circle.fill` |
  | a build failed while the panel was closed | `hammer.fill` with a red dot, until the panel opens |

- Next to the icon, the title can show the Claude session usage in percent and the number of requests that wait for your review. Each part has a switch in Settings.

### 2.2 Panel and pinned window

- The panel is a borderless `NSPanel`, 720 × 820 points by default, minimum 640 × 560. A grip in the footer corner resizes it.
- A drag on empty header or footer space moves the panel. DevHub saves the position and uses it on the next open. A double-click on empty header space moves the panel to its place under the icon again.
- The panel always stays inside the visible area of its screen. It gets smaller when the screen is small.
- A click outside the panel or a switch to another app closes the panel.
- The pin button in the header opens the same content in a normal floating window. That window stays open, keeps its frame and does not close on a click outside.
- A pull request can open in its own window (860 × 720 by default).
- Settings → General → Window "Normal window" replaces the panel with one window that has a title bar, a Dock icon and a main menu. The close button hides it, and it comes to the current desktop when shown. The pin button is hidden in this mode.

### 2.3 Layout from top to bottom

1. **Usage strip** (a switch in Settings). One row per AI provider that is logged in. Claude shows the session and week limits. Copilot shows the premium requests of the month. A click shows reset times and a Refresh button.
2. **Header.** The project menu (switch project, Add Project), the current branch under the project name, the search field with a prompt per tab (⌘F), the palette button (⌘K), the pin button (panel mode only) and the settings button. ⌃⌘1 to ⌃⌘9 select the first nine projects.
3. **Tab bar.** The built-in tabs, then the custom tabs. ⌘1 to ⌘9 select the first nine tabs. The selected tab has the accent colour. When the titles do not fit, the other tabs show only icons.
4. **Search filter bar.** A thin bar with "Clear search" appears only when the current tab is filtered. Without it, a saved query could hide most of a list without a sign.
5. **The view of the selected tab.**
6. **Output panel** (⇧⌘O). Section 2.6.
7. **Footer.** The status text (Ready, the current build or script step with a spinner, the last result), the Output toggle with a running indicator, Quit (⌘Q) and the resize grip.

### 2.4 First launch with no project

DevHub has no default project. With no project, the panel shows "No project yet" and an Add Project button. A project is a folder: the git checkout with the `.xcodeproj` or `.xcworkspace`, or any folder with a `.devhub/project.json` of `kind: command`.

### 2.5 Global shortcut

Settings offers a fixed list: ⌥⌘D (default), ⌃⌥Space, ⌃⌥D or Off. The shortcut opens the panel. When the pinned window is open, it brings that window to the front. It needs no Accessibility permission.

### 2.6 Output panel

- One entry per command: a status dot, the command line, the start time, the working folder, the duration, the exit code and a copy button. Output lines appear while the command runs. A right-click copies the command or the output, or opens the folder in the terminal or Finder.
- The log keeps 300 entries and 4,000 lines per entry.
- The panel is 260 points high by default. A drag on its top edge changes the height, a double-click restores it; the height is saved.
- The filter menu has "Show reads" (read-only commands such as `git status` and `simctl list`, hidden by default) and "Failed only".
- Follow (on by default) keeps the list at the newest command. Off, the list stays where you scrolled.
- A `secret` command (`security`, `gh auth token`) records no output: "Output hidden: it contains credentials."
- An app log stream records no lines: "App log lines are shown in the Logs tab only."
- Search over commands and output, Copy All, Save to a file, Clear. An entry can be opened in the editor (a scratch file in `~/.devhub/scratch/`) or saved on its own.
- The Output panel opens by itself when a command fails.

### 2.7 Command palette (⌘K)

An overlay in the panel with a search field and a result list. Arrows move, Return runs the selected item, Esc closes. It shows at most 60 results. Every word of the query must match. A title that starts with the first word comes first.

Sources:

| Section | Items |
|---|---|
| Tabs | every tab, and Settings |
| Actions | every built-in action, and every config action and script whose `when` condition matches |
| Simulators | Build & Run on a simulator, make a simulator the target |
| Branches | switch to a local branch, Build & Run it, create a worktree for it. With local changes, "Switch to" does not switch: it shows the Git tab and asks you to use Switch or Stash & Switch in the branch row |
| Worktrees | open the folder, Build & Run the worktree |
| Pull requests | show an open request |
| AI sessions | resume a session in the terminal, start a new Claude Code or Copilot CLI session in the project folder |

### 2.8 Notifications

- DevHub posts macOS notifications only while the panel and the pinned window are closed. Settings has the main switch "Notify while the panel is closed" (on by default), one switch per kind with a description, and an "Allow Notifications" button. DevHub asks for the permission only from that button.
- Kinds: builds (finished, launched or failed), test runs of a worktree, more requests waiting for your review, and changes of your own open requests: an approval or a request for changes, failed checks or pipeline, new comments by someone else ("sam commented on #12"), a merge or a close. DevHub compares two reads of the open requests (every 5 minutes, every 2 minutes while the panel is closed); a request that left the list gets one status read to tell a merge from a close.
- The `notify` directive of a script posts a notification when the permission is given, even while the panel is open and with the main switch off, unless its kind is muted.
- A click on a notification opens DevHub at the place of the event (a request, the review list, the Worktrees tab, the run bar). A notification without a place opens the Notifications screen.
- The Notifications screen (the bell in the header, with a badge of unseen events) lists every event of the last 30 days (500 at most, saved between launches) by day, with a filter by kind, the header search, Clear and an arrow that opens the place of an event. Home → Recent shows the last 8 of them.
- The Inbox pane of the Notifications screen lists the unread GitHub notification threads or the pending GitLab to-dos of this repository (`gh api notifications`, `glab api todos`), with the actor, an open action, a browser link and "Mark as Done". A new item posts a notification of the kind "Inbox". The bell badge counts the Inbox items too.

---

## 3. Tabs

| Tab | Purpose | Details |
|---|---|---|
| Home | project card, quick actions, scripts, config problems, recent activity | [`features/home.md`](features/home.md) |
| Git | branch state, remote actions, branches, history, reflog, changes, commit | [`features/git.md`](features/git.md) |
| Pull Requests | GitHub pull requests through `gh`, GitLab merge requests through `glab`, CircleCI jobs through `circleci` | [`features/pull-requests.md`](features/pull-requests.md) |
| Worktrees | list, create, delete and clean worktrees | [`features/worktrees.md`](features/worktrees.md) |
| Simulators | the simulator list and the Build & Run bar | [`features/simulators.md`](features/simulators.md) |
| Device identity | the panel of a simulator row: device ID, profile, clean install | [`features/device-identity.md`](features/device-identity.md) |
| Logs | live app logs, one stream per simulator | [`features/logs.md`](features/logs.md) |
| Network | the mock server, mock sets, GraphQL | [`features/network.md`](features/network.md) |
| AI | Copilot CLI and Claude Code sessions, usage | [`features/ai.md`](features/ai.md) |
| custom tabs | tabs from `.devhub/tabs/*.json` | [`features/custom-tabs.md`](features/custom-tabs.md) |
| Settings | app settings, projects, config folders, Doctor | [`features/settings.md`](features/settings.md) |

Every tab filters its lists with the header search. Every tab shows an empty state with a short hint when there is nothing to show. Errors appear inside the tab with a Retry button.

### 3.1 Home

- **Project card.** Name, path (a click copies it), branch, clean or changed state, and buttons for Finder, the editor, the terminal and the repository web page.
- **Quick actions.** A grid of tiles. The built-ins are Build & Run, Run & Attach, Open in Editor, Open Folder, Terminal, Copy Branch, Repository and New Pull Request; Build (compile only) and Pull Requests appear only when `home.quickActions` lists them. Config actions with the placement `home.quickActions` join the grid. `home.quickActions` in `project.json` sets the order and hides the others.
- **Config problems.** A file that does not decode shows its name and the reason. The other files still load.
- **Scripts.** One row per script from `.devhub/scripts` of every config layer. A row has inputs when the header declares them, a Run button, an inline confirmation, a result area and the last run time.
- **Recent.** The last activity events with an outcome dot.

Why: the actions a developer repeats every day are one click away, and a team can add its own.

### 3.2 Git

- **Header.** A checkout picker (the main checkout or a worktree), branch and short hash, clean or changed state, ahead and behind the upstream and the base branch, stash count, last fetch time. A banner with Continue and Abort appears during a rebase, merge or cherry-pick.
- **Request line.** The pull request of the branch: number, state, checks or pipeline, review state.
- **Action bar.** Fetch, Pull (`--ff-only`), Push, Force Push (`--force-with-lease`, inline confirmation), Rebase on base (`--autostash`), Update base without a switch, Stash and Pop Stash, and config actions with the placement `git.pills`.
- **Segments.** Local, Remote, History, Reflog, Changes.
  - Local: branches sorted by your last checkout, with tags for worktree, upstream state, merged and remote deleted. Actions: Switch (with a stash when there are local changes), Update, Run on target, Create worktree, Delete, Copy, open on the web, the pull request. Config actions with the placement `git.branchRow` are in the context menu.
  - Remote: branches sorted by the last commit. Check out, Run on target, Create worktree.
  - History: the last commits of the chosen checkout, with a "not pushed" tag.
  - Reflog: the recent moves of `HEAD`.
  - Changes: files grouped as conflicts, staged, changed and new, with a diff, stage, unstage, discard and "Open in Editor". A commit box with a prefix from the branch name (`git.commitPrefix`), Amend, Commit (⌘↩) and Commit & Push.
- The remote is `git.remote` (default `origin`). The base branch is `git.baseBranch`, else `<remote>/HEAD`, else `<remote>/main`.

### 3.3 Pull Requests

- DevHub picks the code host from the remote URL. A host name that contains `github` is GitHub. Any other host is GitLab, unless `git.host.kind` says `github` (for GitHub Enterprise on a company domain).
- All words follow the host: "Pull Requests" and `#12` on GitHub, "Merge Requests" and `!12` on GitLab, "checks" or "pipeline".
- The list has four scopes (mine, reviewing, assigned, all), a state filter (open, merged, closed, all) and three styles (Detailed, Calm, Compact).
- The details show the description, review threads, changed files with diffs, checks or pipeline jobs and merge readiness. A changed file can show the whole file at the last commit with the changes in place, and can open in the browser at the last commit, at one line from the menu of a diff line.
- Actions: approve and revoke approval, draft and ready, update branch (rebase on GitLab), merge with optional squash and branch removal, auto-merge, re-run and cancel a check run or pipeline, reply to and resolve a thread, create a new request with labels, "Fix threads with AI" (runs `ai.reviewCommand` in a terminal in the worktree). An action that the host or the repository does not allow is hidden.
- Every 5 minutes DevHub counts the open requests by other people that wait for your review. - A request by someone else can be watched from its row menu. DevHub then reads the list every minute and reports an approval, a request for changes, failed checks, a new comment and the merge or close of that request as a "Watched" notification.
The count appears next to the menu bar icon (`3 PR` on GitHub, `3 MR` on GitLab) and can post a notification.
- Config actions with the placement `pullRequests.row` are in the row menus.

### 3.4 Worktrees

- A toolbar with the base branch, Fetch (`--prune`), Prune (missing folders), Clean Finished (inline confirmation with the list) and New worktree.
- Rows show branch, path, changed files, merged, remote deleted or not pushed tags, ahead and behind, the DerivedData size, the last commit, a locked tag and a "needs bootstrap" tag.
- Actions: Build & Run, Use as Build Source, Open in Finder, editor or terminal, Copy Path, Copy Branch Name, Delete (inline confirmation with warnings for uncommitted changes and unpushed commits; optional removal of DerivedData and the branch). Config actions with the placement `worktrees.row` are in the context menu.
- `git.worktrees.folder`, `include`, `bootstrap` and `bootstrapMarker` control where new worktrees go and how they are prepared.

### 3.5 Simulators and Build & Run

- **Run bar.** Scheme, configuration, build source (the main checkout, a worktree or any branch), Fast (no clean), Clean install, the launch profile and the target simulator. Buttons: Build (⌘B, compile only: no install, no launch), Build & Run (⌘R), Run & Attach (⇧⌘R), Launch (the installed app, no build), Cancel. Config actions with the placement `simulators.runBar` appear under the target. The options are saved per simulator.
- **List.** Favourites first, then one section per iOS runtime, newest first. A row shows the state, the runtime, the target tag, the number of installed apps and the line of the status script (`simulators.statusScript`).
- **Row.** A click on a row makes that simulator the target.
- **Row buttons.** Build & Run on this simulator, deep link and push (the schemes come from `CFBundleURLTypes` of the installed app), the identity panel (section 3.6), Remove All Installed Apps, and the power button (boot or shut down).
- **Row menu.** Open in Simulator.app, Stream App Logs, Launch & Attach Xcode, Copy UDID, Erase Content and Settings (inline confirmation), and config actions with the placement `simulators.row`.
- Remove Apps from All removes the user apps from every simulator, one at a time, with progress and Stop.
- A build of a branch without a checkout creates a worktree first. The main checkout keeps its branch.
- A `kind: command` project runs `build.command`, then `run.command`, instead of `xcodebuild`. Run & Attach is off for these projects.

### 3.6 Device identity

The identity panel of a simulator row appears only when `launch.identity` is set in `project.json`.

- It shows what the app on the simulator uses now: the version, the stored profile, the device ID, the user and the host. These values come from the `state` line of the status script and from the app's `Info.plist`.
- It sets what the next launch uses: a new ID (`launch.identity.idPrefix` plus 8 hex characters), the app's own ID, or a saved ID with an alias. A saved ID can be forgotten.
- It shows a note when the next launch will reinstall the app (section 5.8).
- A tag shows whether the app binary contains the hook text (`launch.identity.hookMarker`).
- Apply & Relaunch launches the installed app again without a build.

Why: a QA flow often needs a fresh device or account ID, or the same ID again later. The app reads the ID only at launch, so DevHub passes it in the environment of the launch.

### 3.7 Logs

- One chip per stream. Each chip is one simulator with its own process, subsystem, level and pause state. "+" adds a stream for a booted simulator.
- The process filter starts with `logs.process`, else `CFBundleExecutable` of the installed app. With `logs.subsystem`, the stream filters by subsystem instead.
- Per stream: levels (All, Info+, Default+, Errors), search, Pause with a count of waiting lines, Copy visible lines, Clear.
- 5,000 lines per stream, in memory only. Lines are masked before DevHub keeps them.
- Config actions with the placement `logs.toolbar` appear in the toolbar.

### 3.8 Network

The Network tab shows only the requests that pass through the DevHub mock server. DevHub does not read any app's own log files.

- **Mode** per simulator: Off (the app talks to its real hosts), Passthrough (DevHub forwards every request and records it) or Mock (the rules of a mock set answer first, the rest is forwarded).
- **Apply & Relaunch** stops the app and launches it again with the server address. The app reads the address only at launch.
- **Status line.** It says whether the app was launched through the server on the current port, launched outside DevHub (the traffic may not reach the server), or launched against an old port.
- **Request list and details.** Method, path, status, duration, request and response headers and bodies, "Copy as cURL", "Copy Response Body" and "Mock This" (a new rule from the request).
- **Mock sets.** Named lists of rules. A rule matches method, path pattern, query and GraphQL operation name, then answers with a fixed response or patches the real response. The sets are files in `network.mocksFolder`, so a team can keep them in the repository.
- **GraphQL.** The list shows the operation name with a `query`, `mutation` or `batch` tag. The details show variables and errors.
- Without `network.baseURLVariable` the mode bar is hidden, and an empty state explains how to enable the mock server.

### 3.9 AI

- Copilot CLI sessions and Claude Code sessions in one list, grouped by day, newest first.
- Filters: the provider (Copilot, Claude, both) and the scope (This project, All).
- A row shows the title, date, folder, branch and the last prompt. Resume opens the configured terminal in the session folder and runs `copilot --resume <id>` or `claude --resume <id>`. The menu has "Copy resume command" and "Copy session ID".
- "New" in the toolbar starts a new Claude Code or Copilot CLI session in the project folder, in the configured terminal. A worktree row offers the same under "Start AI Session Here", and the ⌘K palette lists both tools.
- The usage strip at the top of the panel shows the Claude limits and the Copilot premium requests (section 5.12).

### 3.10 Custom tabs

- Each file in `.devhub/tabs/*.json` adds a tab after the built-in tabs. The first custom tab gets ⌘9. The others have no shortcut.
- A tab has sections. A section lists actions as rows with inputs and a Run button, or it shows the `view` output of a source script (rows with their own actions, key-value pairs or text).
- A source script runs when the tab opens (`onOpen`, the default), on a button (`manual`) or every N seconds.
- Config actions with the placement `tab.<id>` join the tab.
- A config action whose `when` condition does not match is hidden. A section where every action is hidden is not shown.

Why: a team can build a small tool screen (accounts, devices, feature flags) without a change to the app.

### 3.11 Settings

Settings opens from the gear in the header. It is not in the tab bar.

| Section | Content |
|---|---|
| General | launch at login, Dock icon, global shortcut |
| Notifications | the main switch, one switch per kind with a description, the permission state |
| Claude usage | the usage strip, the usage percent in the menu bar |
| Pull Requests | the review count in the menu bar |
| Projects | the project list, Add Project, re-detect scheme and bundle ID, manual values |
| Project config | the three config layers of the project, Create .devhub Example, Reveal .devhub Folder |
| Global config folder | `~/.devhub` with Reveal |
| Tools | editor (Xcode, Cursor, VS Code, Zed) and terminal (Terminal, iTerm2, Ghostty, Warp) |
| Tickets | the default ticket link with `{key}` |
| Git | fetch when the Git tab opens: never, or when the last fetch is older than N minutes |
| Doctor | `git`, `xcodebuild`, `xcrun simctl`, `gh`, `glab`, `copilot`, `claude`, `python3`: version, path or the install command; Accessibility and Notifications permissions |
| About | version |

The Doctor looks for tools in `/opt/homebrew/bin`, `/usr/local/bin`, `~/.local/bin` and the PATH of the app.

---

## 4. Extension system

The full schema with every field, type and default is in `docs/extensions.md`. A complete example folder is in `docs/examples/devhub/`. This section gives the model.

### 4.1 Layers

| Location | Scope |
|---|---|
| `<repo>/.devhub/` | the project; the team decides whether to commit it |
| `~/.devhub/projects/<project folder name>/` | your own additions for one project |
| `~/.devhub/` | global: actions, scripts and tabs for every project |

Each layer may hold `project.json` (not in the global layer), `actions/*.json`, `scripts/*` and `tabs/*.json`. Items merge by `id`. The user layer wins over the project layer. The project layer wins over the global layer. DevHub watches the folders and reloads on a change, with no restart.

### 4.2 `project.json`

It describes how the project builds, runs and connects. Every field is optional. DevHub detects the missing values.

| Group | What it controls |
|---|---|
| `name`, `kind` | the shown name; `xcode` or `command` |
| `xcode.*` | container, scheme, schemes, configuration, bundle ID, bundle IDs per scheme |
| `build.command`, `run.command` | the build and run scripts of a `kind: command` project |
| `git.*` | remote, host kind and name, base branch, protected branches, commit prefix, ticket link, worktree folder and bootstrap, pull request targets, template, stale days, form defaults |
| `ai.commands` | one command per AI tool (`claude`, `copilot`) for "Fix with AI": review threads, failed tests, build errors |
| `launch.profiles[]` | environment, arguments, defaults, storage, upstream, production flag, clean install |
| `launch.identity.*` | the device ID variable and its rules |
| `network.*` | `baseURLVariable`, `mocksFolder` |
| `logs.*` | default process and subsystem |
| `simulators.statusScript` | the status script |
| `home.quickActions` | order and visibility of the Home grid |

### 4.3 Actions

An action is a button that runs something. It has a title, an icon, a tint, placements, a `run` shape, a working folder, inputs, an inline confirmation, refresh targets and visibility conditions (`when`).

- `run` is one of `script`, `command` (an argument array), `terminal` (text run in the terminal) or `open` (a URL or a path).
- Input types: `text`, `number`, `toggle`, `choice`, `branch`, `worktree`, `simulator`, `scheme`, `file`, `folder`. A value reaches a script as `DEVHUB_INPUT_<KEY>` and a `run` string as `{key}`.
- Every run gets the context variables: `DEVHUB_PROJECT_PATH`, `DEVHUB_CHECKOUT_PATH`, `DEVHUB_BRANCH`, `DEVHUB_SIMULATOR_UDID`, `DEVHUB_BUNDLE_ID` and others.

### 4.4 Placements

| Placement | Where |
|---|---|
| `home.quickActions`, `home.scripts` | Home grid, Home scripts list |
| `git.pills`, `git.branchRow` | Git action bar, branch row context menu |
| `worktrees.row` | worktree row context menu |
| `pullRequests.row` | pull request row menus |
| `simulators.runBar`, `simulators.row` | run bar, simulator row overflow menu |
| `logs.toolbar` | Logs toolbar |
| `palette` | the command palette; always added |
| `tab.<id>` | a custom tab |

A row placement gets the values of its row, for example `DEVHUB_BRANCH` or `DEVHUB_SIMULATOR_UDID`, and `DEVHUB_ROW_ID`. Its inputs and confirmation open under that row.

### 4.5 Scripts with a header

Any file in `scripts/` is an action without a JSON file. Lines `# devhub: <key> = <value>` in the first 20 lines set the title, subtitle, icon, tint, inputs, placements, confirmation, working folder and refresh targets. The id is `script:<file name without extension>`. A file without the executable bit shows the hint "Run chmod +x".

### 4.6 The `@devhub` line protocol

A script drives the UI with lines that start with `@devhub ` and hold one JSON object. Other lines are plain output.

| Directive | Effect |
|---|---|
| `progress` | step text and optional fraction in the footer and the run bar |
| `toast`, `copy`, `open` | a toast, the clipboard, open a URL or a path |
| `notify` | a macOS notification |
| `refresh` | refresh stores: `git`, `worktrees`, `simulators`, `scripts`, `logs`, `pullRequests` |
| `error` | mark the run as failed, even with exit code 0 |
| `app` | `build.command` and `run.command` only: the `.app` to install and launch |
| `state` | `simulators.statusScript` only: identity, profile, host, user and version that the app reports |
| `view` | rows with actions, key-value pairs or text in the result area |

---

## 5. Technical playbook

Each item here cost at least one failed attempt. Read the matching item before you change the code it describes.

### 5.1 Menu bar item and panel

- **Do not use `MenuBarExtra(.window)`.** It moves the panel to the icon on every open and every resize, so a saved position is lost. DevHub uses an `NSStatusItem` and its own borderless `NSPanel` subclass: `canBecomeKey` true, `level = .statusBar`, `hidesOnDeactivate = false`, `collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]`, `animationBehavior = .none`, `isMovable = false`. `AppWindows` owns the status item, the panel, the pinned window and the pull request windows.
- **Open at once.** DevHub creates the hosting controller on the first open and keeps it. Later opens only set the frame and show the panel. `openCount` grows by one on each open, and the root view uses it to refresh the stores.
- **Close rules.** A global mouse-down monitor and `NSApplication.didResignActiveNotification` close the panel. The monitor is removed on close.
- **Position.** `WindowLayout` saves the size and the top-left point. The frame stays 12 points inside the visible frame of the screen. A drag view sets `setFrameOrigin` by itself (`mouseDownCanMoveWindow` is false). The resize grip starts from the saved top-left point, so a moved panel does not jump back.
- **Light appearance.** `preferredColorScheme` does not reach an AppKit panel. Set `window.appearance = NSAppearance(named: .aqua)` from an `NSViewRepresentable` in the view tree (`WindowAppearance`) and add `.colorScheme(.light)`. Never set `NSApp.appearance`: the menu bar text would turn black on a dark menu bar.
- **Dock icon:** `NSApp.setActivationPolicy(.regular / .accessory)`. **Launch at login:** `SMAppService.mainApp.register()`. The status `requiresApproval` means: open System Settings → General → Login Items.
- **Global shortcut:** Carbon `RegisterEventHotKey`. It needs no Accessibility permission.
- **Ad-hoc signing.** Each rebuild changes the binary, so macOS may ask for Accessibility again. DevHub shows the System Settings path in the activity line.

### 5.2 Hints

The system `.help` tooltip is slow and often does not appear in a menu bar panel. `HintCenter` keeps the current hint. The `.hint(_:)` modifier reports the frame of its view. `HintOverlay` draws one bubble, at most 260 points wide, under the item or above it when there is no room. A click, a key or a scroll hides it.

### 5.3 `ShellRunner`

- Every process starts through `/usr/bin/env <executable>`. `/opt/homebrew/bin` and `/usr/local/bin` come first in `PATH`.
- **Deadlock trap.** Blocking pipe reads on the Swift concurrency pool hang when 30 or more commands run at the same time. The blocking read runs on a dedicated concurrent `DispatchQueue`, and stderr is read on that queue while stdout is read.
- **Streams.** A cancelled task terminates the process. A cancelled stream ends without an error.
- **Command kinds.** `read` (hidden in the Output panel by default), `action`, `secret` (no output recorded: `security`, `gh auth token`) and `appLog` (`simctl spawn … log`, no lines recorded).
- **`gh` and `glab` kinds.** Both tools follow one rule. A GraphQL query is a read, a GraphQL mutation is an action. An `api` call with `-X GET` is a read, with another method an action. An `api` call without a method is a read when it sends no fields (`-f`, `-F`, `--field`, `--raw-field`, `--input`). The subcommands `view`, `list`, `checks`, `diff` and `status` are reads.
- **Terminal.** `open -a <App> <path>` opens a folder. Ghostty needs `open -na Ghostty --args --working-directory=<path>`. To run a command in a terminal, DevHub writes a temporary `.command` script that removes itself, changes to the folder and runs the command in a login shell.

### 5.4 Git and worktrees

| Need | Command | Note |
|---|---|---|
| Worktrees | `git worktree list --porcelain` | the first block is the main checkout |
| Status | `git status --porcelain=v2 --branch` | `# branch.ab +1 -0` gives ahead and behind |
| Branches | `git for-each-ref refs/heads --format=…` | upstream, track state, date, worktree path, subject |
| Remote branches | `git for-each-ref refs/remotes/<remote> --sort=-committerdate` | skip `<remote>/HEAD` |
| Last visit | `git reflog show --format='%gs%x09%ct' -n 3000 HEAD` | `checkout: moving from A to B` gives the last visit of B |
| Merged | `git branch --merged <base>` | see the rule below |
| Base branch | `git symbolic-ref --short refs/remotes/<remote>/HEAD` | else `<remote>/main`; `git.baseBranch` wins |
| Distance to base | `git rev-list --left-right --count HEAD...<base>` | |
| Not pushed | `git rev-list -n 150 HEAD --not --remotes=<remote>` | "no upstream" alone does not mean "not pushed" |
| Last fetch | modification date of `FETCH_HEAD` | |
| New branch name | `git check-ref-format --branch <name>` | check before `worktree add` |
| Continue rebase | `git rebase --continue` with `GIT_EDITOR=true` | |

Rules:

1. **"Merged" needs a pushed branch.** A new branch with no commits is technically merged into the base. A branch counts as merged only when it is in `--merged`, its upstream is `<remote>/<same name>` and it is 0 commits ahead. Without this rule, Clean Finished deletes fresh worktrees.
2. Clean Finished skips the main checkout, dirty, locked and missing worktrees, and the current build source.
3. A branch merged with a squash counts as merged only after its remote branch is deleted and Fetch runs. DevHub does not try to detect squashes.
4. A worktree is removed with `git worktree remove`. `--force` is used only for a dirty worktree after the inline confirmation.

### 5.5 Code hosts: `gh` and `glab`

- DevHub never reads or stores a code host token. Every call goes through the CLI of the host, which uses its own login.
- **GraphQL for reads.** The list, the details and the branch line use GraphQL:
  - GitHub: `gh api graphql --hostname <host> -f query=… -f name=value` for strings and `-F name=value` for typed values (`Int`, `Boolean`).
  - GitLab: `glab api graphql --hostname <host> -f query=… -f name=value` for strings and `-F name=value` for `true` and `false`.
  - The GitLab branch line uses REST: `projects/<path>/merge_requests?source_branch=…` and `projects/<path>/pipelines?ref=…`.
- **REST and CLI for actions.** GitHub: `gh pr review|ready|merge`, `gh run rerun|cancel`, `gh api -X PUT …/update-branch`, `gh api -X POST repos/<path>/pulls`. GitLab: `glab api -X POST|PUT projects/<path>/merge_requests/<iid>/…` and GraphQL mutations for draft, auto-merge, resolve and pipeline cancel.
- Changed files come from REST (`…/pulls/<n>/files`, `…/merge_requests/<iid>/diffs`), 100 per page.
- `gh` gets `--repo <host>/<path>` (only `<path>` on `github.com`). `glab` gets `--hostname <host>`.
- A missing CLI shows "brew install gh" or "brew install glab". A CLI that is not logged in shows the login command for that host.
- The GitLab GraphQL names stay as GitLab writes them (`mergeRequests`, `MergeRequestState`).

### 5.6 Xcode builds and simulators

Build pipeline for `kind: xcode`:

1. `xcrun simctl boot <udid>`. Exit code 149 means "already booted" and counts as success.
2. `xcodebuild clean` when Fast is off.
3. `xcodebuild -workspace|-project <container> -scheme <s> -configuration <c> -destination id=<udid> ONLY_ACTIVE_ARCH=YES build`, streamed. **No `-derivedDataPath`:** DevHub shares Xcode's DerivedData, so it reuses the cache of the Xcode build of the same checkout.
4. Locate the `.app`: first from the `Touch`, `Validate`, `CodeSign` or `RegisterExecutionPolicyException` lines of the output; else from the DerivedData folder whose `info.plist` has `WorkspacePath` equal to the container (compared without case) under `Build/Products/<Configuration>-iphonesimulator`; last, `xcodebuild -showBuildSettings -json` (about 30 s on a large project). The bundle ID comes from the `Info.plist` of the app.
5. Clean install when needed: uninstall the app and run `xcrun simctl keychain <udid> reset`.
6. `xcrun simctl install`, then write the profile defaults, then `open -a Simulator --args -CurrentDeviceUDID <udid>`, then `xcrun simctl launch --terminate-running-process [--wait-for-debugger] <udid> <bundleID> [args]`. The environment goes through `SIMCTL_CHILD_<NAME>` variables. The launch output `…: <pid>` gives the PID.

Traps:

- **Never pass `CODE_SIGNING_ALLOWED=NO`** or other signing overrides to a build that will run. Embedded frameworks then lose their ad-hoc signature, and dyld on Apple silicon refuses unsigned code even in the simulator. The app dies at launch with "Library not loaded: @rpath/<Framework>".
- **Progress has no total.** `xcodebuild` reports no percentage. DevHub shows a step text: the verb of the line (`SwiftCompile`, `Ld`, `CodeSign`, …) as a word, and the target from `(in target '…')`. The first `error:` line becomes the failure message.
- **DerivedData root.** DevHub reads `IDECustomDerivedDataLocation` from the `com.apple.dt.Xcode` preferences. It deletes a DerivedData folder only under that root. It measures the size with `du -sk`.
- **Simulator list.** `xcrun simctl list devices available -j`. Only iOS runtimes are listed; the parser keeps the platform.
- **Installed app count** without a boot: the number of folders in `~/Library/Developer/CoreSimulator/Devices/<udid>/data/Containers/Bundle/Application`.
- **App container of a shut-down simulator.** `simctl get_app_container` fails. DevHub reads `.com.apple.mobile_container_manager.metadata.plist` in each container folder and compares `MCMMetadataIdentifier` with the bundle ID.
- **Profile defaults.** DevHub gets the data container, or the group container when the suite starts with `group.`, with `simctl get_app_container`. Then it runs `xcrun simctl spawn <udid> defaults write <container>/Library/Preferences/<suite>.plist <key> -string|-bool|-integer|-float <value>`.
- **Launch without a build.** DevHub keeps a copy of the installed app (`ditto`) in `~/Library/Caches/DevHub/Apps/` and installs it again from there for a clean install.
- **Run & Attach.** Xcode has no command to attach. DevHub opens the container in Xcode (`xcode.container`, else the first workspace or project of the checkout), waits up to 150 s for a window, chooses the run destination by UDID through Xcode's AppleScript dictionary, then clicks "Attach to Process by PID or Name…" in the Debug menu through `System Events`. It **sets the value** of the text field of the sheet (keystrokes do not reach it) and clicks Attach. Within 25 s, `ps -o stat= -p <pid>` must no longer start with `T`. This needs Accessibility and the Apple Events usage text in `Info.plist`. The menu item name is the contract with Xcode: a renamed item breaks the attach.
- **Deep link and push.** `simctl openurl <udid> <url>`. `simctl push <udid> <bundleID> <file>` with a JSON body that has an `aps` key.
- One build at a time. Cancel stops `xcodebuild` and returns to the idle state.

### 5.7 `kind: command` projects

`build.command` and `run.command` run in the checkout of the run bar with the context variables. A file without the executable bit runs through `/bin/zsh`, because a fresh clone often loses the bit. Either command may print `@devhub {"app": "<path>"}`. Then DevHub installs and launches that app with the launch profile. A relative path starts at the checkout. Without the line, the script launches the app by itself.

### 5.8 Launch identities, the `state` directive and the clean install rule

- A launch identity is a plan, not stored state. `LaunchPlan` joins the profile, `launch.identity` and the chosen ID. Every launch (Build & Run, Launch, Apply & Relaunch) uses it:
  - `launch.identity.variable` gets the chosen ID;
  - `launch.identity.keptVariable` gets the same ID, or an empty string when no ID is chosen;
  - `launch.identity.args` are added to the arguments.
- The result of a launch is a `LaunchRecord`: bundle ID, profile, ID and mock server URL. DevHub saves it per simulator.
- **The `state` directive.** The status script may print `@devhub {"state": {"identity": "…", "profile": "…", "host": "…", "user": "…", "version": "…"}}`. Every field is optional. DevHub keeps the last report per simulator. This is how DevHub learns what the app really uses: DevHub does not read the app's own log files.
- DevHub reads the status script again 4 s after a launch.
- **Clean install rule** (`CleanInstallPolicy`). It applies only when `launch.identity.cleanInstallOnChange` is true (the default) and the app is installed.
  1. The actual ID is the `state` report, else the ID that DevHub set last.
  2. With a chosen ID: reinstall when the actual ID is different.
  3. With no chosen ID: reinstall only when the actual ID is one that DevHub set or saved.
  
  Why: the app's own ID must not cause a reinstall on every Build & Run. A reinstall ends the user session in the app each time.
- A profile with `cleanInstall: true`, or the Clean install box, always reinstalls.

### 5.9 The mock server

- `NWMockServerRepository` runs one local HTTP server per simulator with Network.framework (`NWListener`). It listens only on `127.0.0.1`.
- The port is stable per simulator: a hash of the UDID in the range 49152 to 59151 (`MockServerPortPolicy`). When that port is busy, the server uses any free port. DevHub starts the servers again on the same ports after a restart, so apps that were launched earlier still reach them.
- **Upstream.** The server forwards to the `upstream` URL of the selected launch profile. A profile with no `upstream`, or with `production: true`, cannot use the server. DevHub refuses and says why.
- **Redirect.** DevHub sets the environment variable named in `network.baseURLVariable` to `http://127.0.0.1:<port>` at launch. The app must read its base URL from that variable. Without `network.baseURLVariable` the server cannot redirect the app, and the mode bar is hidden.
- A Build & Run on a simulator with a running server also gets the variable. If the profile changed, the server forwards to the new upstream.
- A rule answers with a fixed response, or forwards and then patches the JSON response (set or remove a key path). A delay is optional.
- WebSocket upgrades get 501 "WebSocket not mocked yet".
- An upstream error becomes a 502 with the reason.
- Request and response data pass through `NetworkRequestRedactor` before DevHub keeps them.
- Mock sets are JSON files in `network.mocksFolder` (default `~/.devhub/mocks/<project folder name>`). A large body can live in a separate file next to the set.

### 5.10 GraphQL monitoring and mocking

- **Operation name** (`GraphQLParser`):
  1. a POST body: `operationName`, else the name in the `query` document;
  2. a GET request: the `operationName` and `query` parameters of the URL;
  3. a persisted query with no `query` text: `operationName`, when `extensions` is present;
  4. a batch (a JSON array): every operation.
- The kind comes from the first word of the document: `query`, `mutation` or `subscription`. A document that starts with `{` is a `query`.
- A response with an `errors` array counts as failed, even with status 200.
- **Rule matching** (`MockRuleMatcher`). The first enabled rule that matches wins. A rule matches when the method, the path pattern, the query pairs and the operation name all match.
  - `*` in `operationName` matches any text, for example `Get*`.
  - A batch matches when one of its operations matches.
  - A rule without `operationName` ignores GraphQL.
  - A rule with `operationName` never matches a request that is not GraphQL.

### 5.11 Logs

- `xcrun simctl spawn <udid> log stream --style ndjson --level debug --predicate 'process == "<name>"'`, or `subsystem == "<name>"` when a subsystem is set.
- Only `os_log` and `Logger` lines arrive. `print()` output does not reach the system log. The empty state says so.
- **Masking before storage.** `LogRedactor` masks `Bearer <token>`, JWTs (`eyJ….….…`) and the values after `authorization`, `x-auth-token`, `access_token`, `refresh_token`, `id_token`, `token`, `password`, `secret`, `api_key` (any case, `:` or `=`).
- New lines are added every 150 ms. A stream keeps 5,000 lines. Pause keeps a queue with a count.

### 5.12 AI sessions and usage

**Copilot CLI** (`~/.copilot/session-state/<uuid>/`):

- `workspace.yaml` has flat `key: value` lines (`id`, `cwd`, `branch`, `name`, `summary`, `created_at`, `updated_at`). A small parser reads it. No YAML library.
- `events.jsonl`: DevHub reads only the `user.message` lines. A folder without `events.jsonl` was never used and is skipped.
- Title: `name`, else `summary`, else the first user message, else the folder name.

**Claude Code** (`~/.claude/projects/<folder>/<uuid>.jsonl`):

- DevHub reads lines by their prefix and does not decode every line: `custom-title`, `ai-title`, `last-prompt`, and the first object with `cwd`. The files are large, so the result is cached per file by modification date.

**Claude usage:**

- The token comes from `security find-generic-password -s "Claude Code-credentials" -w`, else from `~/.claude/.credentials.json`.
- `GET https://api.anthropic.com/api/oauth/usage` with `Authorization: Bearer <token>` and `anthropic-beta: oauth-2025-04-20`.
- **Never refresh the token.** A refresh rotates the refresh token and can end the Claude Code login. An expired token shows "Run `claude` once."

**Copilot usage:**

- The token comes from `gh auth token` first, and from the keychain item `copilot-cli` second. The keychain read stops after 10 s and is not tried again until the app restarts. Why: macOS can show a dialog that asks to allow `/usr/bin/security`, and a background refresh must not show it again and again.
- `GET https://api.github.com/copilot_internal/user` with `Authorization: token <token>`. DevHub shows the premium requests used, the percent, the reset date and the plan.

Both usage endpoints are not documented. The parsers accept unknown keys. An error shows inside the strip with Retry. Usage refreshes every 5 minutes, and on panel open when the data is older than 60 s.

### 5.13 Persistence

- Projects, the selected project, settings, the selected tab, per-simulator run options, launch settings, log streams, favourites and the target simulator live in `UserDefaults`, through the `KeyValueStore` port.
- DevHub never writes into a `.devhub/` folder, except "Create .devhub Example" and the mock set files in `network.mocksFolder`.

### 5.14 Build scripts

- `Scripts/build.sh [Debug|Release]` runs the layer check and the anonymity check, then `xcodebuild -quiet` into `DerivedData/`, and prints the `.app` path. Any other output is a warning or an error.
- `Scripts/test.sh` runs `swift test` on the package and prints one summary line.
- `Scripts/smoke.sh` starts the Debug build for 3 s and prints `alive` or `dead`.
- `Scripts/run.sh` builds Debug, quits a running copy of this build and opens the new one. `Scripts/install.sh` copies a Release build to `/Applications/DevHub Generic.app`. After `Scripts/install-hooks.sh`, a commit or merge on `main` that changes the app runs the install in the background.
- The scripts stop only the build of this repository, by its path. Another app with the name DevHub keeps running.

---

## 6. Acceptance checklist

Run these checks by hand on a test repository with a remote and the example folder from `docs/examples/devhub/`. Each check names what you should see.

### Shell

1. Run `Scripts/build.sh`. It prints `layers: ok`, `anonymous: ok` and the app path. `Scripts/smoke.sh` prints `alive`.
2. Start the app with no project. The panel shows "No project yet" and an Add Project button.
3. Add the test repository. The header shows the project name and the branch.
4. Move the panel, resize it, close it and open it again. It opens at the same place and size. A double-click on empty header space moves it under the icon again.
5. Press the pin button. A floating window opens with the same content and stays open after a click outside.
6. Choose ⌥⌘D in Settings, close the panel and press ⌥⌘D. The panel opens.
7. On a clean checkout, press ⌘K, type a branch name and choose "Switch to <branch>". The branch changes, and the command appears in the Output panel. With local changes, the palette shows the Git tab and a toast instead.
8. Run a command that fails (for example Pull on a branch that has no upstream). The Output panel opens by itself and shows a red entry.

### Home

9. The project card shows the path, the branch and the clean or changed state.
10. Run a script with an input from `.devhub/scripts`. The footer shows its progress, a toast appears, and the result area shows its output.
11. Change `.devhub/project.json` and save it. Home reloads with no restart. Break the JSON. Home shows a config problem with the file name.

### Git

12. Fetch, Pull, Push, Stash and Pop Stash work, and each appears in the Output panel.
13. Switch to another branch with local changes. DevHub stashes the changes first.
14. In Changes, stage a file, see its diff and commit. The commit box starts with the ticket prefix of the branch.
15. Create a worktree from a local branch row. The Worktrees tab shows it.

### Pull Requests

16. On a GitHub repository with `gh` logged in, the tab lists open pull requests in the four scopes.
17. Open one request. The details show threads, files and checks. Reply to a thread and resolve it.
18. Create a new pull request with a label from the form. It appears in the list.
19. Run `gh auth logout` (or test on a machine without `gh`). The tab shows the login or install command. The other tabs still work.

### Worktrees

20. Create a worktree for a new branch. It appears in `git.worktrees.folder`. Files from `git.worktrees.include` are copied.
21. Merge a test branch on the remote, Fetch, then Clean Finished. Only finished, clean worktrees are listed and deleted.

### Simulators and Build & Run

22. Build & Run the main checkout on a shut-down simulator. The simulator boots, the footer shows the steps, and the app launches.
23. Choose "Other branch…" with a branch that has no checkout, then Build & Run. A new worktree appears, and the main checkout keeps its branch.
24. Choose a launch profile with `env` and `defaults`. The app receives the values.
25. Run & Attach. Xcode opens and attaches to the app (Accessibility is needed).
26. Open a deep link and send a push from the row menu.

### Device identity

27. With `launch.identity` set, open the identity panel of the target simulator. Choose New ID, then Build & Run. The app is installed again, and the `state` line of the status script shows the new ID.
28. Build & Run again with the same ID. The app is not installed again.

### Logs

29. Start streams on two booted simulators. Both chips show lines at the same time.
30. Change the level to Errors, search a word, press Pause and Resume. The counter of waiting lines grows while the stream is paused.

### Network

31. With `network.baseURLVariable` and a profile `upstream`, choose Passthrough and press Apply & Relaunch. The list shows the requests of the app.
32. On a request, press "Mock This", change the body and choose Mock mode. The app gets the mocked answer.
33. Add a patch rule with `operationName` for a GraphQL request. Only that operation changes.
34. Choose a profile with `production: true`. The mock server refuses to start and says why.

### AI

35. The tab lists Copilot and Claude sessions grouped by day. The scope "This project" shows only sessions in the project folder and in its worktrees.
36. Press Resume. The terminal opens in the session folder and resumes the session.
37. The usage strip shows the Claude limits, and the Copilot premium requests when Copilot is logged in.

### Custom tabs and Settings

38. Add a file to `.devhub/tabs/`. A new tab appears after the built-in tabs and opens with ⌘9.
39. A source script section shows rows from its `view` output, and a row action runs.
40. Settings → Doctor lists every tool with a version or an install command, and the state of the Accessibility and Notifications permissions.
41. Allow notifications. Start a build that fails, and close the panel before the build ends. A notification appears, and the menu bar icon shows a red dot until the panel opens.
42. Enable "Launch at login" and restart the Mac. DevHub starts.
