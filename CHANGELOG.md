# Changelog

All notable changes to DevHub. Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Newest first.

Every session that changes code adds lines under **Unreleased** before it ends. One line per user-visible change, described as behaviour, not as files. Scripts, hooks, skills and docs go under **Infrastructure**.

## [Unreleased]

### Added
- Build & Run: the run bar lists the compiler errors and warnings of the build, errors first. A click opens the file at that line in the editor from Settings.
- Simulators: the sliders button in a row opens QA settings for a booted simulator: light or dark appearance, text size, a clean 9:41 status bar, a location from a city list, the language and region, privacy permissions for the app (grant, revoke, reset) and a screenshot to the Desktop.
- Home has a "Today" card: requests that wait for your review, your requests with failed checks, finished worktrees and booted simulators. A click opens the right tab (or the request).
- Switch projects from the keyboard: ⌃⌘1 to ⌃⌘9 select the first nine projects in the order of Settings → Projects, and the project menu shows these shortcuts. The ⌘K palette lists "Switch to project …" for the other projects.
- Settings → Project config → "Create .devhub Starter" writes `.devhub/project.json` with the values DevHub found for the project (name, scheme, bundle ID, remote, code host, base branch) and opens it in the editor. A good first step for a new project; the example folder stays for a full reference.
- Pull request details list every check or pipeline job of the last commit, failed first. The log button shows the last 200 lines of a job log inside DevHub, with Copy Log. Retry runs one failed or cancelled job again. Works for GitHub Actions and GitLab jobs.
- Pull request diffs: hover a line and click the bubble with a plus (or right-click it, "Comment on This Line…") to start a new review thread on that line, on GitHub and GitLab. The box opens under the line; ⌘Return posts, Esc closes.
- Pull request details have a comment box. "Comment" (⌘Return) posts a comment on the request on GitHub and GitLab. "Request Changes" sends the text as a review that asks for changes, on GitHub, for a request by someone else. A failed post keeps the text.
- A right click on the menu bar icon opens a menu: Show DevHub, the list of projects (a click switches to the project and shows DevHub), Keep Mac Awake, Settings… and Quit DevHub. A left click still opens or closes DevHub.
- Settings → General → Window: "Normal window" turns DevHub into a window app. It gets a title bar, a Dock icon and a main menu (DevHub, File, Edit, Window). The close button and ⌘W hide the window and DevHub keeps running. The menu bar icon, the global shortcut and a click on the Dock icon show the window on the current desktop; the icon and the shortcut hide it when it is already in front. The window opens at launch when it was open at quit. "Menu bar panel" stays the default.
- Git: pin, label and add a note to a local branch. The star (or "Pin to Top" in the menu) moves the branch into a "Pinned" group at the top of Local, and "Delete all…" never offers it. "Add Labels & Note…" opens a form under the row; labels show as coloured tags, the note under the subject, and the search finds both. The marks stay in DevHub, per project.
- Simulators: drag a favorite row onto another favorite row to change the order of the Favorites section. The order is saved, and a new favorite goes to the end.
- AI tab: a star on a session row adds it to the favorites. Favorites come first in their own section, stay visible in the "This project" scope, and come first in the ⌘K palette.
- Home has a "Keep Mac awake" switch. While it is on, the Mac does not go to sleep when idle, and the menu bar icon shows a cup. The ⌘K palette turns it on and off. Quitting DevHub turns it off.
- The `network.toolbar` placement puts config actions under the filters of the Network tab, with the chosen simulator. `refresh: ["network"]` reads the mock sets again after an action.
- Scripts, commands and the status script get `DEVHUB_PROFILE` (the launch profile of the simulator), `DEVHUB_HOST` (`github` or `gitlab`), `DEVHUB_APP_CONTAINER` and `DEVHUB_DATA_CONTAINER` (the app and data folders of the app on the simulator). The example `.devhub` folder has a "Clear App Caches" action that uses them.
- The run bar profile picker marks a `production: true` profile with a warning sign, and shows a red "production" tag next to the picker while that profile is selected.
- DevHub has an app icon: a `</>` sign on an indigo square. It shows in Finder, in the Dock when the Dock icon is on, and in notifications.
- Settings → Projects: the circle arrows button finds the scheme and bundle ID of a project again in the project files. Settings → Global config folder shows `~/.devhub` with Reveal, or "not created".
- Settings → Doctor lists git, xcodebuild, simctl, gh, glab, copilot, claude and python3 with the version and path, or "missing" with the install command. It also shows the Accessibility and Notifications permissions. "Check Again" reads them again.
- macOS notifications while the panel is closed: a finished or failed Build & Run, more requests waiting for your review, and every `notify` line of a script. Settings → Notifications has the switch and asks for the permission once. The menu bar icon shows a circle while a build runs and a red dot after a failed build until the panel opens.
- Command palette (⌘K or the ⌘ button in the header): one search over tabs, built-in and config actions, simulators (Build & Run on, make target), local branches (switch, Build & Run, create worktree), worktrees (open, Build & Run), pull requests and AI sessions (resume). Arrow keys move, Enter runs, Esc closes. An action with inputs asks for them inside the palette.
- GraphQL in the Network tab: a request shows its operation name and a `query`, `mutation` or `batch` tag, the details list the operations, variables and errors, and a response with `errors` counts as failed. A mock rule can match a GraphQL operation name (`*` allowed), and "Mock This" on a GraphQL request fills it in. The mock set file format is documented in `docs/extensions.md` section 9.
- Custom tabs from `.devhub/tabs/*.json` appear after the built-in tabs (⌘9 for the first one). A section lists its actions with Run, inputs and results, or the rows that its source script prints, read again on open, by hand or every N seconds. Actions placed at `tab.<id>` get their own section. The header search filters the rows.
- Launch identities from `launch.identity` in `.devhub/project.json`: the identity panel of a simulator and the run bar choose an ID (New, Saved, Own) and an alias. Build & Run and "Launch" pass the ID in `launch.identity.variable` (and `keptVariable`) with `launch.identity.args`. When the app on the simulator has another ID, the launch reinstalls it and resets the simulator keychain; "Own" reinstalls only when the app still carries an ID that DevHub set.
- The identity panel shows the profile, host, user, ID and version that the status script reports in a `state` line, the hook tag found in the app binary (`hookMarker`, `keptVariable`) and the time of the last launch from DevHub.
- The mock server takes its upstream from the `upstream` of the launch profile the app uses (the reported profile, else the stored one, else the run bar profile), refuses a `production` profile, and passes its URL in `network.baseURLVariable`. "Apply & Relaunch" also writes the `defaults` of that profile. The Network bar tells when the app was launched without DevHub, points to an old server, or uses another profile than the server.
- The example `.devhub` folder (Settings → "Create .devhub Example") shows `launch.identity`, the profile `upstream`, `storage` and `production` keys, `network.*`, and a status script that prints a `state` line.
- The Network tab hides the mock server bar when `network.baseURLVariable` is not set and says how to turn the mocks on. Saved mock servers start again at app start only for projects with that key, and never for an upstream of a `production` profile.
- `network.mocksFolder` in `.devhub/project.json` moves the mock sets of a project into that folder, for example into the repository so the team shares them.
- `.devhub/project.json` reads `launch.identity`, the profile fields `storage`, `upstream` and `production`, and `network.baseURLVariable` and `network.mocksFolder`.
- The usage strip has a Copilot row when Copilot is logged in: the premium request meter with its reset date, or "No premium request limit". The expanded strip shows the plan and an "Open Usage" link for each provider. The Copilot token comes from `gh auth token`, else from the `copilot-cli` keychain item.
- The AI tab lists Copilot CLI sessions (`~/.copilot/session-state`) next to Claude Code sessions. A provider filter (Copilot, Claude, Both) is saved. Each row shows its provider, and Resume runs `copilot --resume` or `claude --resume` in the session folder.
- The Logs tab streams several simulators at once: one chip per simulator, `+` adds a booted simulator, `×` closes a stream. Each stream keeps its own process, subsystem, level, pause state and lines, and the streams come back after a restart. A new stream starts with `logs.process` and `logs.subsystem` from `.devhub/project.json`; with a subsystem the stream filters by subsystem instead of process.
- `simulators.statusScript` shows its result under the name of the booted, favourite and target simulators, and under the target of the run bar. The line is read again after each launch and on refresh. A failure, a missing script or a timeout shows in red.
- Build & Run for `kind: command` projects: the run bar shows `build.command → run.command` instead of the scheme pickers and runs both in the selected checkout. Their output goes to the build log, `progress` lines move the progress bar, an `error` line or a non-zero exit fails the run, and an `app` line makes DevHub install and launch that app with the launch profile.
- Launch profiles from `launch.profiles` in `.devhub/project.json`: the run bar has a profile picker with a summary. Build & Run passes the environment and the arguments of the profile to the app, writes its `defaults` into the app container (or the app group container) after install, and does a clean install when the profile says so. The choice is saved per simulator.
- The configuration picker of the run bar also lists the configuration of `xcode.configuration` when it is not Debug or Release.
- Config actions in pull request rows: the `pullRequests.row` placement puts an action into the menu of each open request, with `DEVHUB_PR_NUMBER`, `DEVHUB_PR_URL` and `DEVHUB_BRANCH`. `refresh: ["pullRequests"]` reads the requests again after an action, and `when: {"host": "github"}` shows an action only for that code host.
- `builtin.pullRequests` in `home.quickActions` opens the pull request tab.
- `git.pullRequests` in `.devhub/project.json`: the order of the target branches, the description template, the days until the `stale` tag and the defaults of the new request form. Without a template setting, GitHub projects read `.github/pull_request_template.md`.
- `ai.reviewCommand` in `.devhub/project.json` sets the command that "Fix threads with AI" runs (default `claude "$(cat {prompt})"`).
- Pull requests from GitHub: when the remote is on `github.com` (or `git.host.kind` is `github`), the merge request tab and the Git status line read pull requests through `gh`: the four scopes, the state filter, checks, review threads, files with their diff, labels. Approve, take back an approval, draft and ready, update branch, merge, auto-merge, re-run and cancel a check run, create, reply and resolve go through `gh` as well.
- Home reads the `.devhub/` config of the selected project: the quick actions follow `home.quickActions` (built-in and config actions), the Scripts list shows the executable files of `.devhub/scripts` in all three layers with their header, and a red box lists config problems with a Reload button.
- Running a config action or a script asks for its inputs and confirmation inline, streams its output to the Output panel, shows `progress` in the footer, and handles `toast`, `copy`, `open`, `refresh`, `error` and `view` lines. Remembered inputs come back on the next run.
- Editing a file in `.devhub/` reloads the config while the panel is open.
- Settings has a "Project config" section: the three config folders, "Create .devhub Example" and "Reveal .devhub Folder".
- Config actions appear in every placement: buttons in the Git header (`git.pills`), the Simulators run bar (`simulators.runBar`) and the Logs toolbar (`logs.toolbar`); menu items in branch rows (`git.branchRow`), worktree rows (`worktrees.row`) and simulator rows (`simulators.row`). A row action gets the branch, worktree path or simulator of its row. Its inputs and confirmation open under the row.
- A `simulator` input lists booted simulators first.
- The example `.devhub` folder marks its helper scripts (DerivedData clean, booted simulators, simulator status) with `placements = palette`, so Home does not list them next to the actions that run them.

### Changed
- A launch of an installed app waits until the simulator has booted before it installs or launches.
- The status line under a simulator is read again 3 s after a launch, so it shows what the app wrote at start.
- The saved identity settings of the old app (`simulators.identity`) are not read: every simulator starts with no chosen ID. Choose the ID again in the identity panel.
- The Output panel hides the output of `gh auth token`, like the output of `security`.
- The Claude tab is the AI tab (tab id `ai`).
- The deep link menu of the simulator messaging panel lists the URL schemes of the installed app (`CFBundleURLTypes` in its `Info.plist`) instead of fixed example schemes. The push alert template uses the project name as its title.
- Build & Run follows `xcode.*` in `.devhub/project.json`: the run bar lists `xcode.schemes` in their order, starts with `xcode.scheme` and `xcode.configuration` when the simulator has no saved choice, and `xcodebuild` uses `xcode.container` (also inside worktrees).
- "Fix Threads with Claude" is "Fix Threads with AI": it runs `ai.reviewCommand`.
- The tab, the Git header, branch rows, Home and Settings use the words of the code host: "Pull Requests", `#12`, "checks" and "Open in GitHub" for GitHub; "Merge Requests", `!12`, "pipeline" and "Open in GitLab" for GitLab. On GitHub the rebase action is "Update Branch from <target>" and the retry action is "Re-run Failed Checks".
- "Revoke Approval" and "Merge When Checks Pass" are hidden when the host does not allow them for you (on GitHub: without write access, or when the repository does not allow auto-merge).
- The toolbar of the pull request tab moves its menus to a second line when the panel is narrow, so the count and the refresh button stay visible.
- The review prompt for "Fix threads with AI" says "Review page" instead of naming GitLab.
- The merge request types, stores and views use pull request names (`PullRequestSummary`, `CodeHostRepository`, `PullRequestsStore`). The tab id is `pullRequests` (`DEVHUB_TAB=pullRequests`).
- The merge request features work with a code host value instead of a GitLab URL: the kind (GitHub or GitLab), the host name and the repository path. `git.host.kind` and `git.host.name` in `.devhub/project.json` set them for a custom host. Error messages name the tool (`gh` or `glab`) and its login command.
- The `build-and-run` skill describes the package scripts, headless snapshots and the current debug switches.
- "Open in Xcode" on changed file rows is now "Open in Editor": the file opens in the editor chosen in Settings (`xed` for Xcode, `code --goto` for VS Code, `cursor --goto` for Cursor, `zed` for Zed, else `open -a`), at the line when the editor supports it. Merge request files and threads open the same way.
- The ticket chip, the commit box prefix and the new merge request title follow `git.commitPrefix.pattern` and `format`. `git.ticketURL` sets the ticket link per project; the Settings link stays the fallback.
- "Clean Up" never offers the branches of `git.protectedBranches` (default `main`, `master`, `develop`, `dev`) or the base branch.
- `git.remote` in `.devhub/project.json` names the remote (default `origin`). Fetch, pull, push, force push, the remote branch list, the merged check, the web link and the base branch fallback (`<remote>/HEAD`, else `<remote>/main`) use it.
- Worktrees follow `git.worktrees` in `.devhub/project.json`: new worktrees go into `folder` (default: next to the repository as `<repo>-<branch>`), the `include` files are copied from the main checkout, and the `bootstrap` script runs when `bootstrapMarker` is missing in the worktree, or once after creation when there is no marker. The fixed `init.sh`, `.worktreeinclude` and `.claude/worktrees` conventions and the "claude" tag are gone.
- DevHub now runs on the package architecture of the main DevHub: seven modules in `Packages/DevHubKit`, Swift 6, about 1,480 tests. The tabs are Home, Git, GitLab, Worktrees, Simulators, Logs, Network and Claude, with Settings behind the gear.
- The first launch has no project. The panel shows "No project yet" with an Add Project button.
- The Network tab shows only the requests that pass through the DevHub mock server.
- "Copy for Slack" is now "Copy Link with Title".
- The base branch falls back to `origin/main`.
- The Scripts setting (a fixed scripts folder) is gone: scripts live in `.devhub/scripts`.

### Fixed
- The Claude usage strip reads the per-model weekly limits (for example "Week · Fable") from the new `limits` list of the usage API, so it shows the same values as Claude Desktop.
- The "This project" scope of the AI tab also keeps sessions started in the worktrees of the project, also when a worktree folder sits next to the project folder.
- The hint of "Delete all…" in the merged branches group names the branches that stay: the base branch and `git.protectedBranches`. Before, it always said "dev, main and master".
- "Copy chmod Command" in the menu of a script that is not executable copies the command. Before, the menu item did nothing.
- "Clean Finished" counts only the DerivedData that was really removed. A worktree that could not be removed no longer adds its size.
- The command palette and custom tabs hide a config action whose `when` condition does not match, like Home and the rows do. A custom tab section with only hidden actions is not shown.
- "Switch to <branch>" in the command palette no longer runs `git switch` over local changes. It opens the Git tab and asks you to choose Switch or Stash & Switch in the branch row.
- Branch, commit and new request links in the Git tab follow `git.host.kind`. Before, a GitHub Enterprise host without "github" in its name got GitLab paths.
- The new request form shows "Delete source branch after merge" and "Squash" only on GitLab. GitHub does not take them when a request is created.
- "Load more" in the request list names the real page size: 50 on GitHub, 100 on GitLab.
- The menu bar shows "PR" on GitHub and "MR" on GitLab next to the review count. Before, it showed "MR" for every host.
- The Output panel sorts `gh` and `glab` calls the same way: GraphQL queries, GET calls and `view`, `list`, `checks`, `diff` and `status` count as reads; mutations and calls that send data count as actions. Before, every `glab api` call was a read and every `gh` call was an action.
- GitLab GraphQL calls send `true` and `false` as booleans (`-F`), so draft, auto-merge and resolve mutations get the type GitLab expects.
- Run & Attach, Launch & Attach and "Open in Xcode" open the workspace or project from `xcode.container`. Before, they opened the first one in the folder.
- "Duplicate" of a mock set keeps the GraphQL operation name of each rule. Before, the copy matched every request on the path.
- The Network tab names the real mock set folder (`network.mocksFolder` or `~/.devhub/mocks/<project>`) in the delete question and the picker hint. The mock server info and the "Copy as cURL" hints describe what DevHub does today.
- Deep links, push, "Uninstall" in a simulator row and the process name of a new log stream use the bundle ID from `xcode.bundleID`, `xcode.bundleIDs` or the last launch, like the identity panel. Before, they used only the bundle ID from Settings.
- The Build feature sources and tests are in the repository: the `build/` line of `.gitignore` also matched the `Build/` folders on macOS. A fresh clone builds again.
- The base branch no longer shows a "merged" tag and no longer lands in the "Merged · safe to delete" section.
- Releasing a store whose event handler held another store no longer crashes: `AppEvents` released a handler while it changed the handler list.

### Removed
- Slack commands (tab, catalog file, history). A config action or a script covers that need.
- The reader of one app's own session log (network requests, device ID, user and host).
- The built-in device identity preset and the built-in default project.

### Infrastructure
- `docs/STATUS.md`, `docs/SPEC.md` and ADR 005 describe the window mode and the new features. Decisions 37 to 40 are new.
- The `DEVHUB_PULL_REQUEST=<n>` debug switch opens a request in the Pull Requests tab for a headless snapshot.
- `AppContainer` is the app delegate (`@NSApplicationDelegateAdaptor`), so a click on the Dock icon shows DevHub. The `DEVHUB_WINDOW_MODE` debug switch sets the window mode.
- The headless snapshot recipe in the `build-and-run` skill and `docs/testing.md` starts the app with its full path, so the `pkill` line at the end really stops it. Before, every snapshot left a DevHub copy running in the menu bar.
- ADR 005 plans the window mode, the ports from the main DevHub, pull request comments, checks, project setup and daily tools.
- `GlabIntegrationTests`: with `DEVHUB_GITLAB_PLAYGROUND=<host>/<owner>/<project>` it creates a merge request on a GitLab test project and runs draft, ready, a thread with a reply, resolve and merge through the real `glab` code. The first run on a real host confirmed that GitLab rejected the old string booleans.
- Documentation for the finished rewrite: `docs/features/<tab>.md` for every tab, a new `docs/SPEC.md`, `docs/adr/004-launch-identities-and-network.md`, `docs/testing.md`, the `code-host` skill, and rewritten `add-feature`, `panel-window`, `ui-components`, `xcode-toolchain`, `update-docs`, `data-layer` and `testing` skills. The `providers-and-shell` skill is merged into `data-layer`.
- `docs/extensions.md`: the `xcode.bundleID` default and use, the `production` key, the `notify` directive and the custom tab shortcut now match the code.
- `Scripts/check-layers.sh` fails on `MainActor.assumeIsolated`. The three window observers, the hot key and the command log hop to the main actor with `Task { @MainActor in }` or `DispatchQueue.main.async { @MainActor in }`.
- `Scripts/make-app-icon.swift <folder>` draws the app icon PNGs in every size. Run it on `DevHub/Assets.xcassets/AppIcon.appiconset`.
- README: a documentation table, the tools that Doctor checks, "First project in two minutes", ⌘K, ⌘9 and notifications.
- Deleted `legacy/`, the sources of the first generic app. Everything it did now lives in the package.
- Debug launch switch `DEVHUB_PALETTE=<query>` opens the command palette.
- Debug launch switches `DEVHUB_LAUNCH_ID=<id>` (the launch identity for `DEVHUB_BUILD_RUN`) and `DEVHUB_MOCK=<simulator>,<mode>[,<set>]` (Apply & Relaunch of the mock server).
- `DEVHUB_BUILD_RUN`, `DEVHUB_BUILD_PROFILE` and `DEVHUB_BUILD_BRANCH` run Build & Run headless in Debug builds.
- `MergeDetail`, `PipelineStatus` and `PullRequestThread` are `MergeReadiness`, `CheckStatus` and `ReviewThread`. `PullRequestsStore` is split into the store, `PullRequestsStore+Filter`, `PullRequestListCache`, `PullRequestActionTexts` and `PullRequestsPreferenceKeys`.
- `GhIntegrationTests` reads a GitHub test repository through `gh` when `DEVHUB_PLAYGROUND=owner/repo` is set.
- ADR 003 describes the code host port and the GitHub mapping.
- `ConfigStore` loads and watches the `.devhub/` layers of the selected project and posts `configChanged`. `ConfigActionsStore` runs config actions and scripts: prompt for inputs and confirm, remembered inputs, the context environment, the `@devhub` directives, refresh requests and failures in the activity log. New events `configChanged` and `refreshRequested`. Not on screen yet.
- New ports `ConfigRepository`, `ScriptRunning` and `ToolLocating` with live types (`FileConfigRepository` reads the three `.devhub/` layers and watches them, `ShellScriptRunner` streams a script with an optional timeout, `PathToolLocator`), mocks and spies. `ShellRunner.stream` takes an environment.
- The `.devhub/` config models, the layer merge, the script header and directive parsers, the action catalog and context rules, and the example folder are now Domain types with tests (not yet wired to the screens). `Scripts/generate-example-config.sh` writes `ExampleConfig.swift` from `docs/examples/devhub/`.
- `Scripts/check-anonymous.sh` checks the whole tree and the last commit message for names of the owner's projects (from `~/.devhub/anonymity-denylist.txt`, outside the repository) and for bundle IDs, plist suites and hosts that are not sample values. `Scripts/build.sh` runs it after `Scripts/check-layers.sh`.
- `Scripts/test.sh`, `Scripts/check-layers.sh`, `docs/ARCHITECTURE.md`, `.claude/rules/*` and the skills `add-use-case`, `data-layer`, `testing` come from the package-based DevHub, with sample values renamed. New rule `.claude/rules/anonymity.md`.
- Debug launch switches `DEVHUB_PROJECT`, `DEVHUB_OPEN_PANEL`, `DEVHUB_TAB`, `DEVHUB_SNAPSHOT`, `DEVHUB_SNAPSHOT_DELAY`, `DEVHUB_RUN_ACTION`, `DEVHUB_REQUEST_ACTION`, `DEVHUB_SHOW_OUTPUT`, `DEVHUB_GIT_OPS` in Debug builds.
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
