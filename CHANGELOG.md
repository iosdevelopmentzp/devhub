# Changelog

All notable changes to DevHub. Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Newest first.

Every session that changes code adds lines under **Unreleased** before it ends. One line per user-visible change, described as behaviour, not as files. Scripts, hooks, skills and docs go under **Infrastructure**.

## [Unreleased]

### Added
- Home reads the `.devhub/` config of the selected project: the quick actions follow `home.quickActions` (built-in and config actions), the Scripts list shows the executable files of `.devhub/scripts` in all three layers with their header, and a red box lists config problems with a Reload button.
- Running a config action or a script asks for its inputs and confirmation inline, streams its output to the Output panel, shows `progress` in the footer, and handles `toast`, `copy`, `open`, `refresh`, `error` and `view` lines. Remembered inputs come back on the next run.
- Editing a file in `.devhub/` reloads the config while the panel is open.
- Settings has a "Project config" section: the three config folders, "Create .devhub Example" and "Reveal .devhub Folder".
- Config actions appear in every placement: buttons in the Git header (`git.pills`), the Simulators run bar (`simulators.runBar`) and the Logs toolbar (`logs.toolbar`); menu items in branch rows (`git.branchRow`), worktree rows (`worktrees.row`) and simulator rows (`simulators.row`). A row action gets the branch, worktree path or simulator of its row. Its inputs and confirmation open under the row.
- A `simulator` input lists booted simulators first.
- The example `.devhub` folder marks its helper scripts (DerivedData clean, booted simulators, simulator status) with `placements = palette`, so Home does not list them next to the actions that run them.

### Changed
- Worktrees follow `git.worktrees` in `.devhub/project.json`: new worktrees go into `folder` (default: next to the repository as `<repo>-<branch>`), the `include` files are copied from the main checkout, and the `bootstrap` script runs when `bootstrapMarker` is missing in the worktree, or once after creation when there is no marker. The fixed `init.sh`, `.worktreeinclude` and `.claude/worktrees` conventions and the "claude" tag are gone.
- DevHub now runs on the package architecture of the main DevHub: seven modules in `Packages/DevHubKit`, Swift 6, about 1,480 tests. The tabs are Home, Git, GitLab, Worktrees, Simulators, Logs, Network and Claude, with Settings behind the gear.
- The first launch has no project. The panel shows "No project yet" with an Add Project button.
- The Network tab shows only the requests that pass through the DevHub mock server.
- "Copy for Slack" is now "Copy Link with Title".
- The base branch falls back to `origin/main`.
- The Scripts setting (a fixed scripts folder) is gone: scripts live in `.devhub/scripts`.

### Fixed
- Releasing a store whose event handler held another store no longer crashes: `AppEvents` released a handler while it changed the handler list.

### Removed
- Slack commands (tab, catalog file, history). A config action or a script covers that need.
- The reader of one app's own session log (network requests, device ID, user and host).
- The built-in device identity preset and the built-in default project.

### Infrastructure
- `ConfigStore` loads and watches the `.devhub/` layers of the selected project and posts `configChanged`. `ConfigActionsStore` runs config actions and scripts: prompt for inputs and confirm, remembered inputs, the context environment, the `@devhub` directives, refresh requests and failures in the activity log. New events `configChanged` and `refreshRequested`. Not on screen yet.
- New ports `ConfigRepository`, `ScriptRunning` and `ToolLocating` with live types (`FileConfigRepository` reads the three `.devhub/` layers and watches them, `ShellScriptRunner` streams a script with an optional timeout, `PathToolLocator`), mocks and spies. `ShellRunner.stream` takes an environment.
- The `.devhub/` config models, the layer merge, the script header and directive parsers, the action catalog and context rules, and the example folder are now Domain types with tests (not yet wired to the screens). `Scripts/generate-example-config.sh` writes `ExampleConfig.swift` from `docs/examples/devhub/`.
- `Scripts/check-anonymous.sh` checks the whole tree and the last commit message for names of the owner's projects (from `~/.devhub/anonymity-denylist.txt`, outside the repository) and for bundle IDs, plist suites and hosts that are not sample values. `Scripts/build.sh` runs it after `Scripts/check-layers.sh`.
- `Scripts/test.sh`, `Scripts/check-layers.sh`, `docs/ARCHITECTURE.md`, `.claude/rules/*` and the skills `add-use-case`, `data-layer`, `testing` come from the package-based DevHub, with sample values renamed. New rule `.claude/rules/anonymity.md`.
- Debug launch switches `DEVHUB_PROJECT`, `DEVHUB_OPEN_PANEL`, `DEVHUB_TAB`, `DEVHUB_SNAPSHOT`, `DEVHUB_SNAPSHOT_DELAY`, `DEVHUB_RUN_ACTION`, `DEVHUB_REQUEST_ACTION`, `DEVHUB_SHOW_OUTPUT` in Debug builds.
- `Scripts/run.sh`, `smoke.sh` and `install.sh` stop only this build, by its path, not every process called DevHub.
- The stop hook also watches `Packages/` and `.claude/rules/`.
- `waitUntil` in tests waits up to 10 s instead of 2 s, so store tests do not fail on a busy machine.
- `docs/adr/001-port-from-main-devhub.md`: the plan for the port, with a step log.
- The first generic app moved to `legacy/` (not built) as the port source.

## [MVP] - 2026-10-17

The first generic app, before the rewrite.


### Added
- Menu bar icon and own floating panel (not MenuBarExtra): left click toggles, right click shows Open, Pin, Settings and Quit. The panel closes on outside click, app switch and Esc.
- The panel remembers its size and position, stays 12 points inside the screen, moves by its empty header space and resizes from the footer grip.
- Pin button opens the same content in a floating window. Global shortcut (default ⌥⌘D, fixed list in Settings).
- Header with project name and branch, search field with a prompt per tab (⌘F), tab bar with ⌘1 to ⌘9, search filter bar, footer with status, Output toggle (⇧⌘O) and Quit.
- Tabs Home, Git, Worktrees, Simulators, Logs, AI and Settings. Home shows a project card and quick actions. Git shows the branch state. Worktrees, Simulators, Logs and AI show sample data and say so.
- Shared UI blocks, hover hints, click to copy and toasts.
- `DEVHUB_OPEN_PANEL=1`, `DEVHUB_TAB` and `DEVHUB_SNAPSHOT=<png path>` open the panel at launch and write a picture of it, for checks without a screen.

- Every command the app runs shows in the Output panel (⇧⌘O) with its folder, output, duration and exit code. Read-only commands are hidden until "Show reads" is on. Commands with secrets or app logs show no output. The panel has search, Copy All and Clear, and opens by itself when a command fails.
- Home has a "Run a test command" section (git version, macOS version, a command that fails) to see the Output panel at work.
- Footer shows the running command or the last failure.
- Toasts for copied text and failed commands.
- Project card and Git tab show the real branch and change count. Open folder, editor and terminal buttons run `open -a` through the shell.
- Failed and finished actions appear in the Recent list on Home.
- `DEVHUB_RUN_TEST_COMMANDS=1` runs the Home test commands at launch.

- Projects: add a folder (folder picker), switch from the header picker, remove and detect again. DevHub finds the Xcode workspace or project, the schemes, the bundle ID, the git remote and the base branch. The list and the selection are saved. Home shows an empty state with "Add project…" on first launch.
- Settings has a Projects section: path, kind, scheme, bundle ID, switch, detect again, open the `.devhub` folder, remove, and "Create .devhub example".
- Config loader for `.devhub/` in three layers (user, project, global) with merge by id, inline errors that name the file and the reason, and a watcher that reloads when files or folders change. `xcode.schemes` and `xcode.bundleIDs` work.
- Action system: built-in actions plus config actions plus scripts with a `# devhub:` header. Inputs of every type, `remember`, inline confirm, `{placeholders}`, context variables, and the `@devhub` line protocol (progress in the footer, toast, copy, open, refresh, error, view).
- Home: project card with Finder, editor, Terminal and Repository buttons, quick actions grid (order and hiding from `home.quickActions`), Scripts list with last run time and "Run chmod +x" hint, config problems list. The temporary "Run a test command" section is gone.
- Repository and New pull request (or merge request) buttons open the GitHub or GitLab web page of the current branch.
- `DEVHUB_PROJECT`, `DEVHUB_RUN_ACTION`, `DEVHUB_REQUEST_ACTION`, `DEVHUB_SEARCH`, `DEVHUB_SHOW_OUTPUT` and `DEVHUB_SNAPSHOT_DELAY` and `DEVHUB_CREATE_EXAMPLE` help to check the UI without a screen.

- Git tab is real: checkout picker, branch and hash, tags (clean, upstream, ahead and behind base, stash count, last fetch), and a banner for a rebase, merge or cherry-pick in progress with Continue, Abort and Terminal.
- Git pills: Fetch, Pull (fast-forward only), Push (sets the upstream when there is none), Force Push, Rebase on base, Update base without switching, Stash, Pop Stash, config actions with placement `git.pills`, and Terminal, New PR/MR and Web icons. Force Push and Rebase ask for an inline confirm.
- Git segments Local, Remote, History and Changes. The chosen segment is remembered.
- Changes segment: diff view (4 000 line cap, notice for binary files), stage, unstage, discard (inline confirm), open in editor, Stage All, Unstage All, commit box with a prefix from `git.commitPrefix`, Amend, Commit (⌘↩) and Commit & Push.
- Pull request or merge request line through `gh` and `glab`. When the tool is missing or not logged in, the line shows the command with a copy button.
- Worktrees tab is real: toolbar (base, DerivedData total, Fetch with prune, Prune, Clean Finished, New worktree), sections (main, in progress, finished, missing), rows with tags and DerivedData size, delete with inline confirm and checkboxes, create from a local branch, a remote branch or a new branch, copy of the `git.worktrees.include` files, bootstrap script, and config actions with placement `worktrees.row`.
- `branch` and `worktree` action inputs are searchable pickers over live data. `branch` with `default: "current"` starts with the branch of the checkout chosen in the Git tab. `cwd: checkout`, `DEVHUB_CHECKOUT_PATH` and `DEVHUB_BRANCH` follow that checkout.
- Logs tab is real: one chip per simulator stream, a "+" button with a searchable list of booted simulators, several streams at once, level filter, search, Pause with a count of waiting lines, Copy visible lines, Clear, and up to 5 000 lines per stream with a counter for dropped lines. Streams and levels are saved.
- Log lines are masked before they are stored: bearer tokens, JWTs and secret keys never reach the list.
- Simulators tab shows the live list of available simulators.
- Simulators run bar: pick a scheme, configuration, build source (main checkout, a worktree or a branch with an existing worktree), Fast and Clean install, then Build & Run, Run & Attach or Launch. Shows build progress, the result and a Run & Attach accessibility notice. Row actions launch, send a deep link or a push, stream logs, remove apps, boot or shut down, and uninstall. Favorites star, target marker, Open in Simulator.app and Copy UDID.
- AI tab is real: Copilot sessions from `~/.copilot/session-state` and Claude sessions from `~/.claude/projects`, grouped by day, with a provider switch (Copilot, Claude, Both), a scope (This project, All), search, count, refresh and Resume in the configured terminal.
- Usage strip is real: Claude session and week limits and Copilot premium requests, with reset times, plan, Retry, and a refresh every 5 minutes while the panel is open.
- Settings can show the usage strip and the Claude or Copilot usage percent in the menu bar.
- Debug switches `DEVHUB_GIT_SEGMENT`, `DEVHUB_GIT_OPS`, `DEVHUB_LOG_STREAM`, `DEVHUB_LOG_REDACT_CHECK`, `DEVHUB_AI_SCOPE`, `DEVHUB_AI_PROVIDER` and `DEVHUB_USAGE_EXPAND`.

### Changed
- The Home empty state and the example `project.json` (now with `xcode.schemes` and `xcode.bundleIDs`) were polished.
- `DEVHUB_PROJECT_PATH` and the working folder no longer choose the project. Use the project list or `DEVHUB_PROJECT`.
- A failed secret command (for example `gh auth token` without a login) no longer opens the Output panel. `gh auth token` counts as a secret command.

### Fixed
- The change count says "1 change" instead of "1 changes".
- A cancelled stream shows as "Cancelled", not as a failure.
- `BuildStore`, the store behind the Simulators run bar, was missing from the feature commit (never added to git) and the app did not build. Reconstructed from its call sites on a temporary branch: builds with `xcodebuild`, locates, caches, installs and launches the app, and runs Run & Attach. Known gap: a branch build source needs an existing worktree for that branch; it does not create one.

### Removed
- The sample data banners on Git, Worktrees, Logs, AI and Simulators, because these screens now show live data.

### Infrastructure
- Skills, `AGENTS.md` and `docs/STATUS.md` updated for the M0 and M1 structure.
- `README.md`, `DevHub.command` and `Scripts/make-launcher.sh`.
- Provider protocols with mock types for Git, Xcode, Simulators, Logs, AI, Config, Scripts and Workspace, bundled in `Providers`.
- M2 docs: `docs/extensions.md` now says that script paths start at the layer's `.devhub` folder and that header script ids have no file extension. Skills, `AGENTS.md` and `docs/STATUS.md` describe the config loader, the action system and the new debug switches.
- Seed files: `AGENTS.md`, `CLAUDE.md`, `docs/SPEC.md`, `docs/STATUS.md`, `docs/extensions.md`, examples, skills, hooks, `Scripts/ai`.
- Provider protocols and live types for pull requests (`gh`, `glab`), worktrees, simulators, app logs, AI sessions and usage. One git write path (`GitCommand` and `GitExecutor`).
- M3, M5 and M6 docs folded into `docs/STATUS.md`, `docs/extensions.md`, `AGENTS.md` and the skills. `build-and-run` has a table of the debug launch switches.
