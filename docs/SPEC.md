# DevHub — specification for a one-session build

Working name: **DevHub**. Rename before the session if you want another name. Search and replace `DevHub`, `devhub` and `DEVHUB_` in this folder.

This document is written for an AI coding agent (GitHub Copilot CLI first, Claude Code second) and for the human owner. The agent reads this file, `AGENTS.md` and the skills under `.github/skills/` and builds the app in one session, milestone by milestone.

---

## 0. How to read this document

1. **The result is a working app.** Not a prototype, not a mock. Every screen in section 5 runs real commands through the provider layer.
2. **No tests.** No unit tests, no UI tests, no test target. The check is `Scripts/build.sh` with zero warnings plus a manual run. Time goes into features and the build check, not into tests.
3. **Config over code.** Every project builds differently. Where a generic rule cannot cover a project, the difference goes into the project's `.devhub/` folder (section 6), never into Swift. A project name, path, bundle ID or branch name written in Swift is a bug.
4. **The agent decides.** When the spec leaves a choice open, pick the simplest option that keeps the layers in section 7 clean, write the decision into `docs/STATUS.md` and continue. Do not stop to ask.
5. **Priorities.** Items marked **P0** must work at the end of the session. **P1** should work. **P2** is done when time remains. An unfinished P1 or P2 item goes to `docs/STATUS.md` under "Next steps" with what is missing.
6. **The reference UI (Appendix A) may be revisited.** Keep the patterns: one panel, tabs, rows with hover actions, inline confirmation, search in every list, searchable pickers. Change colours, spacing or grouping when it makes the screen clearer.
7. **Section 8 is a list of verified solutions and traps.** Every item there cost at least one failed attempt in an earlier tool with the same goals. Read it before writing the related code. Do not re-discover these problems.
8. **Plain English everywhere.** Documentation, UI text, hints, commit messages, changelog: short sentences, common words, no idioms.

---

## 1. What DevHub is

A personal macOS menu bar panel for daily development work across many repositories. One click on the menu bar icon opens a panel with tabs:

| Tab | Purpose |
|---|---|
| Home | Project card, quick actions, scripts, recent activity |
| Git | Branch state, remote actions, branches, history, changes, commit |
| Worktrees | List, create, delete, clean finished worktrees |
| Simulators | Device list, run bar: build and run any branch from any scheme on any simulator |
| Logs | Live system log of the app, one stream per simulator |
| AI | Copilot CLI and Claude Code sessions with one-click resume; usage quotas in the strip at the top |
| Settings | Projects, terminal, editor, shortcuts, toggles, doctor |
| custom tabs | Defined in `.devhub/tabs/*.json` (section 6) |

Plus a global **command palette** (⌘K) that searches everything, and an **Output panel** that shows every command the app runs.

The core is generic. Project knowledge lives in `.devhub/` config files that the user edits at any time: quick actions, git pills, scripts with inputs, launch profiles, custom tabs. A script can drive the UI through a small line protocol.

### Principles

1. **Config over code** (see 0.2).
2. **Every external command is visible.** One `ShellRunner`; every run lands in the Output panel with its working folder, output, duration and exit code.
3. **Never switch the user's branch without being asked.** A build of another branch uses a worktree. Updates use fast-forward only.
4. **Secrets never leave memory.** Tokens are read for one request and dropped. Commands that print secrets have their output hidden. Log lines are masked before they are stored.
5. **Search everywhere.** Every list filters by the header search. Every picker with more than a handful of items is a searchable picker.
6. **Fast open.** The panel opens at once with the last state and refreshes in the background.
7. **Degrade, do not break.** When an optional tool (`gh`, `glab`, `copilot`, `claude`) is missing or not logged in, the feature shows what to install or run, and the rest of the app works.
8. **The repo documents itself.** `AGENTS.md`, `CHANGELOG.md`, `docs/STATUS.md` and the skills are kept current by the agent in the same session that changes the code (section 9).
9. **Clear layers, small files.** Section 7. A file over ~300 lines is a sign to split.

### Non-goals for v1

- Physical devices (`devicectl`). Idea for later.
- App Store, notarization, sandbox. Ad-hoc signing only. A sandbox would block `git`, `xcrun` and `xcodebuild`.
- Chat or messaging integrations. If a project needs them, it adds an action with a script.
- An AI chat inside the app. Only session lists, resume and quotas.
- Dark theme. Light appearance is forced on the panel window (see 8.2). A theme switch is a P2 idea.

---

## 2. Before the session (human checklist)

1. Create the folder and `git init`.
2. Copy everything from `seed/` into the folder, including the dot folders `.github` and `.claude`.
3. Create the Xcode project in that folder: macOS App, SwiftUI, product name `DevHub`, bundle ID of your choice (for example `local.devhub.app`), **no tests** (uncheck "Include Tests"). Use the installed macOS SDK as the deployment target. Then set these build settings on the app target:

   | Setting | Value | Why |
   |---|---|---|
   | `ENABLE_APP_SANDBOX` | `NO` | shell commands |
   | `CODE_SIGN_STYLE` | `Automatic`, no team, "Sign to Run Locally" | no developer account needed |
   | `INFOPLIST_KEY_LSUIElement` | `YES` | menu bar only, no Dock icon |
   | `SWIFT_VERSION` | `5.0` | Swift 5 language mode |
   | `SWIFT_DEFAULT_ACTOR_ISOLATION` | `MainActor` | views and stores on the main actor by default |
   | `SWIFT_APPROACHABLE_CONCURRENCY` | `YES` | |
   | `INFOPLIST_KEY_NSAppleEventsUsageDescription` | `DevHub drives Xcode's Debug menu to attach the debugger to an app on the simulator.` | without it macOS rejects the Apple Events used by Run & Attach |
   | `GENERATE_INFOPLIST_FILE` | `YES` | |

   Keep the Xcode 16 **synchronized folder**: a file added under `DevHub/` on disk joins the target. The agent edits `project.pbxproj` only for build settings, never for file lists.
4. Open the project once in Xcode so the `DevHub` scheme exists (`xcodebuild -scheme` needs it). Build once. Commit.
5. Tools on the machine: Xcode with command line tools, `git`, `python3` (used by the hook scripts), a terminal app. Optional: `gh`, `glab`, `copilot`, `claude`.
6. Optional: add a remote (`git remote add origin …`) and push once, so the agent can push its commits. Without a remote the agent commits locally only.
7. Start the session in the folder:
   - Copilot: `copilot`, then: `Read AGENTS.md and docs/SPEC.md. Implement the specification milestone by milestone (section 3). After every milestone run Scripts/build.sh, update CHANGELOG.md and docs/STATUS.md, and commit.`
   - Claude Code: `claude`, same prompt.

---

## 3. Milestones

Each milestone ends with: `Scripts/build.sh` clean (zero warnings), a launch of the app (`Scripts/run.sh`) to check the screen by hand or with the headless smoke check, `CHANGELOG.md` and `docs/STATUS.md` updated, a commit and a push. Inside a milestone every finished feature is also a commit and a push (see "Commits and pushes" below).

| # | Milestone | Priority | Done when |
|---|---|---|---|
| M0 | Skeleton: own status item and panel (8.1), window layout and drag, header, tab bar, footer, theme, shared components, hints, settings store, project session, mock providers, previews, `Scripts/build.sh`, `run.sh`, `install.sh` | P0 | the panel opens from the menu bar with a mock Home and all tabs navigable |
| M1 | `ShellRunner`, `CommandLog`, Output panel, activity log, toasts and click-to-copy | P0 | a command run from Home shows in the Output panel with exit code and duration |
| M2 | Projects (add, detect, switch), config loader and watcher for `.devhub/`, Home (project card, quick actions, scripts), action runner with inputs and the script line protocol | P0 | a script from `.devhub/scripts` with an input runs, streams output, reports progress in the footer |
| M3 | Git tab (header, pills, local, remote, history, changes, diff, commit) and Worktrees tab | P0 | fetch, pull, push, switch, commit, create and delete worktree work on a real repo |
| M4 | Simulators tab and Build & Run: schemes, configurations, build source (main, worktree, any branch), target, launch profiles, run options per simulator, Run & Attach, clean install, deep link, push | P0 | a branch without a checkout builds in a new worktree and launches on the chosen simulator while the main checkout keeps its branch |
| M5 | Logs tab: one stream per simulator, levels, search, pause, copy, redaction | P1 | two simulators stream at the same time in two chips |
| M6 | AI tab: Copilot and Claude sessions with resume; usage strip with Claude and Copilot quotas | P1 | sessions grouped by day, filtered to the project; resume opens the terminal in the right folder |
| M7 | Extensions: custom tabs from config, placements everywhere, hot reload on file change, command palette | P1 | editing a JSON file under `.devhub/` changes the UI without a restart |
| M8 | Polish: in-app build log viewer, menu bar icon state, doctor in Settings, keyboard navigation in lists, notifications when the panel is closed, launcher `.command` | P2 | |

If time runs out: M0 to M4 are mandatory. The action system with inputs and placements belongs to M2 and is mandatory.

### Commits and pushes: the remote is always a working app

The session may stop at any moment (token limit, network, a crash). The owner must be able to clone the remote at any moment, run `Scripts/run.sh` and get a working app with every feature finished so far. So:

- **Every pushed commit builds clean and launches.** Before a commit: `Scripts/build.sh` prints only the app path, then the headless smoke check (8.13) says `alive`. A commit that does not pass this is not made.
- **Push after every finished feature, not only after a milestone.** A feature is finished when its screen or action works end to end with real data and the build is clean. Typical cadence: one push every 20 to 40 minutes of work.
- **Never leave the remote half-done.** A feature that is not finished yet is committed only when the app still builds and the unfinished part is not reachable from the UI (no tab, no button), or when it shows a clear "not yet" empty state. Prefer small, finished steps: a new screen with mock data that works is better than a half-wired real screen that crashes.
- When the repository has a remote (`git remote get-url origin` succeeds) and a push works (`git push -u origin <branch>` returns 0), push after every commit. When the push fails for access reasons, record that in `docs/STATUS.md` under "Known gaps", keep committing locally with the same rules, and do not retry on every commit.
- Work on the branch the session started on. Never force-push. Never rewrite history of a pushed commit.
- No time goes into tests: no unit tests, no UI tests. The build and the smoke check are the gate.
- Small commits with a clear message (`feat:`, `fix:`, `docs:`, `chore:`), the body in plain English. `CHANGELOG.md` gets its line in the same commit as the feature.
- M0 includes a `README.md` in the new repo with the three commands a clone needs: `Scripts/run.sh`, `Scripts/install.sh`, `DevHub.command`. Keep it true as the app grows.

---

## 4. Shell of the app

### 4.1 Menu bar item and panel

- Status item with a template icon (SF Symbol `hammer.fill` or similar). Left click toggles the panel. Right click opens a small menu: Open, Pin, Settings, Quit.
- The icon shows state: a small dot or a spinner-like symbol while a build runs, a red dot after a failure until the user opens the panel (P2). Optional usage percent next to the icon (Settings).
- The panel: borderless `NSPanel`, default 720 × 820 points, minimum 640 × 560, resizable by a grip in the footer corner, movable by dragging empty header or footer space. The position is saved and used on the next open. Double-click on empty header space puts it back under the icon. The panel always stays 12 points inside the visible frame of its screen and shrinks when the screen is small. Details and traps in 8.1.
- A click outside the panel or a switch to another app closes it. Esc with an empty search field closes it.
- Pin button in the header: opens the same content in a floating window that stays open and on top; the panel closes. The window remembers its frame.
- Global shortcut (Settings, default ⌥⌘D, a fixed list of choices) opens the panel or brings the pinned window to the front.

### 4.2 Layout from top to bottom

1. **Usage strip** (optional, Settings): one row per AI provider that is logged in: Claude session and week bars, Copilot premium requests. Click expands reset times and a Refresh button. Section 5.8.
2. **Header**: project switcher (searchable, with "Add project…"), the current branch under the project name, header search field with a prompt per tab (⌘F focuses, Esc clears), pin button, settings button.
3. **Tab bar**: pills from `FeatureRegistry` plus custom tabs from config. Selected pill filled with the accent colour, white text. ⌘1 … ⌘9. When titles do not fit, tabs show icons only (`ViewThatFits`).
4. **Search filter bar**: a thin accent bar that appears only when the current tab is filtered by a query, with "Clear search". Without it a saved query hides most of a list with no sign.
5. **Feature view** for the selected tab.
6. **Output panel** (toggle in the footer, ⇧⌘O): fixed height, shows every command. Section 4.4.
7. **Footer**: status label (Ready, current build step with a spinner, last build result, last failure), Output toggle with a running indicator, "⌘1–N tabs" hint, Quit, resize grip.

### 4.3 Command palette (⌘K, P1)

A popover with a search field and a result list. Sources: tabs, built-in and config actions, scripts, simulators (boot, make target, run on), local branches (switch, run on target, create worktree), worktrees (open), AI sessions (resume), settings toggles. Enter runs the first match, arrows move. Each result shows a small category tag. The palette reuses the `SearchablePicker` component.

### 4.4 Output panel

- One entry per command: status dot (running, success, failure), the command line, working folder, duration, exit code, copy button. Output lines stream in while the command runs; long outputs show the last 8 lines with "show all". 300 entries, 4 000 lines per entry.
- "Show reads" toggle: read-only commands (`git status`, `simctl list`, …) are hidden by default to keep the list short.
- Commands classified as **secret** (`security`) record no output: "Output hidden: it contains credentials." App log streams record no lines either: "App log lines are shown in the Logs tab only."
- Search over commands, output and errors. Copy all. Clear.
- The panel opens by itself when a command fails.

---

## 5. Screens

Every screen: filters its lists with the header search; shows `ContentUnavailableView.search` for an empty filtered result; shows an empty state with a short hint when there is nothing; shows errors inline with a Retry button; ends with a `#Preview` using mock providers.

### 5.1 Home

- **Project card**: icon tile, name, path (click copies), branch tag, status tag (clean or N changes), ahead/behind, buttons: Finder, Xcode (or the configured editor), Terminal, Repository (web). Data from the main checkout.
- **Quick actions**: a grid of tiles (four columns at 720 points, fewer when narrower). Built-in: Build & Run, Run & Attach, Open in Xcode, Open folder, Terminal here, Copy branch, Repository, New pull/merge request. Config actions with placement `home.quickActions` join the grid. The order and the hidden ones come from `.devhub/project.json → home.quickActions` (P1); default: built-ins first.
- **Scripts**: rows from `.devhub/scripts/` of the project and from `~/.devhub/scripts/` (global). Each row: icon, title, description, file name, last run time, Run button, inputs when the header declares them. Header format in `docs/extensions.md`. Section header has: the folder path (click opens Finder), a lightbulb that shows the header format, a reload button.
- **Recent**: the last 8 activity events (title, detail, time, outcome dot). Clear.

### 5.2 Git

- **Header card**: checkout picker (main checkout or any worktree, searchable), branch name and short hash (click copies), tags: clean or N changes, upstream ↑↓ or "no upstream", "N ahead / M behind <base>", stash count, last fetch time, refresh button. A banner with Continue / Abort / Terminal appears while a rebase, merge or cherry-pick is in progress.
- **PR / MR line** (P1): number, state (open, draft, merged), conflicts, review or merge status, latest pipeline or checks. Click opens the web page. Through `gh` for GitHub and `glab` for GitLab, detected from the remote URL. Not logged in: show the login command with a copy button.
- **Pills** (an `ActionBar` that never cuts buttons): Fetch, Pull (`--ff-only`), Push (`-u` when no upstream), Force Push… (`--force-with-lease`, inline confirm), Rebase on <base>… (fetch, then `rebase --autostash`, inline confirm), Update <base> (fast-forward without switching), Stash / Pop Stash, plus config actions with placement `git.pills`. Right side icons: Terminal here, New PR/MR, Open branch on web.
- **Segments**: Local N | Remote N | History | Changes. The tab remembers the segment.
  - **Local**: sorted by the user's last checkout (reflog), current first. Each row: name, worktree tag when checked out elsewhere, changes in that worktree, ↑↓, "local only", "remote deleted", "merged". Actions: Switch, Update (fast-forward, also inside another worktree), Run on target, Create worktree, Delete (`-d`; `-D` with inline confirm), Copy, Web, PR/MR.
  - **Remote**: sorted by last commit. Author, subject, date. Actions: Check out (creates a tracking branch), Run on target, Create worktree, Web.
  - **History**: last 150 commits of the chosen checkout, "not pushed" tag on commits that are on no remote branch. Click copies the hash. Full hash and subject in the hint.
  - **Changes**: files of the chosen checkout grouped as conflicts, staged, changes, new. Click shows the diff (text, capped at 4 000 lines, binary notice). Per file: stage, unstage, open in editor, discard (inline confirm; a new file is deleted). Stage All / Unstage All. Commit box with a prefix built from the branch name (configurable pattern, default ticket key such as `ABC-123: `), Amend, Commit (⌘↩), Commit & Push. No partial staging in v1.

### 5.3 Worktrees

- Toolbar: base branch name, total DerivedData size, Fetch (`--prune`), Prune (missing folders), Clean Finished… (inline confirm with the list), New worktree (branch picker with search; a new name branches from the base).
- Sections: main checkout, in progress, finished (merged into base or remote branch deleted), missing folder.
- Row: branch, path, changed files, merged / remote deleted / not pushed tags, ↑↓, DerivedData size, last commit and time, locked tag, "needs bootstrap" tag with a Run button.
- Actions: Run on target, Use as build source, Open in Finder, Open in editor, Terminal, Copy path, Copy branch, Delete (inline confirm with warnings for uncommitted changes and unpushed commits, checkboxes "Delete DerivedData (size)" and "Delete branch").
- Rules in 8.4.

### 5.4 Simulators

- **Run bar card**:
  - Scheme (searchable, from the project's `.xcscheme` files), Configuration (Debug, Release, plus any from the project), Build source: main checkout, a worktree, or "Other branch…" with a searchable branch picker (a branch without a checkout gets a worktree on the next run), Fast (skip clean), Clean install (delete app, reset simulator keychain, install).
  - Target: the simulator chosen in the list, with its runtime.
  - Launch profile (from config; "none" when the project defines none): environment variables, launch arguments, defaults written into the app container. Section 6.4.
  - Buttons: Run & Attach, Build & Run (prominent), Launch (installed app, no build), Cancel while running.
  - Run options are saved per simulator and restored when the simulator becomes the target.
  - While a build runs the footer shows the step text (Compiling · Target, Linking, Installing…). The bar is indeterminate (8.5). A failure shows the first `error:` line with "Show log" (in-app viewer in M8; a temp file opened in Console before that).
- **List**: count line ("119 simulators · 36 with apps"), Remove Apps from All… (inline confirm, progress with Stop). Sections: Favorites, then one per runtime, newest first. Only iOS runtimes in v1; the parser keeps the platform so others can be added.
- **Row**: status dot, device icon, name, runtime tag, "target" tag, favorite star, "Booted · N apps installed", optional project status line (6.5). Hover actions: Launch, Deep link / Push (popover with URL field and recent links; push payload editor with alert and silent templates, JSON check), Stream logs, Remove all apps (one tap, no confirm), Power, overflow menu: Open in Simulator.app, Make target, Copy UDID, Erase… (inline confirm), Uninstall <bundle id>, Open data container, Screenshot (P2), Appearance light/dark (P2).
- **Create / delete simulator** (P2): `simctl create`, `simctl delete`.

### 5.5 Logs

- Chips bar: one chip per active stream ("iPhone 17 · booted", a dot, a close ×), a "+" that opens a searchable picker of booted simulators. The process name defaults to the project app's executable (from the installed app's `Info.plist`); editable. Optional subsystem filter from config.
- Per stream: level segmented control (All, Info+, Default+, Errors), the header search filters lines, Pause with a counter of waiting lines, Copy visible lines, Clear. 5 000 lines in memory per stream, nothing on disk. Lines are masked by `LogRedactor` before storage (8.7).
- Row: time, level colour, subsystem · category, message (selectable, click copies).
- The chosen streams and levels survive a relaunch; streams restart on demand, not automatically.

### 5.6 AI

- Toolbar: provider segmented control (Copilot | Claude | Both), scope (This project | All), count, refresh.
- Rows grouped by day: provider tile, title, date, folder path, branch tag, last prompt preview (one line), Resume button. Resume opens the configured terminal in the session folder and runs `copilot --resume <id>` or `claude --resume <id>`. A missing folder disables Resume with a hint.
- Copilot sessions come from `~/.copilot/session-state/<id>/workspace.yaml` and `events.jsonl`; Claude sessions from `~/.claude/projects/*/<id>.jsonl`. Parsing rules in 8.9.
- Copilot is listed first because it is the main tool.

### 5.7 Settings

- General: launch at login (`SMAppService`), show Dock icon, global shortcut (fixed list), show usage strip, show usage percent in the menu bar (per provider), terminal app (Terminal, iTerm2, Ghostty, Warp, …), editor (Xcode, VS Code, Cursor, …).
- Projects: list with path, detected kind (Xcode workspace, Xcode project, command-based), scheme, bundle ID; Add project… (folder picker), remove, re-detect, "Open .devhub folder", "Create .devhub example".
- Global config folder: `~/.devhub` with a Reveal button.
- Doctor (P2): a table of tools (git, xcodebuild, simctl, gh, glab, copilot, claude, python3) with version or "missing" and the install command; Accessibility permission state with a button that opens System Settings.

### 5.8 Usage strip

- **Claude**: session (five hour) and week limits, plus per-model week limits when the response has them. Source in 8.10.
- **Copilot**: premium requests used and remaining for the month, reset date, plan name. Source in 8.11.
- Each provider row: name, one or two bars with percent, chevron to expand reset times and plan, Refresh. Errors show inline ("Claude Code is not logged in. Run `claude` once.") with Retry.
- Polling every 5 minutes while the panel is open; refresh on open when older than 60 seconds.

---

## 6. Extension system (`.devhub/`)

Normative schema with every field: `docs/extensions.md`. Examples: `docs/examples/devhub/`. This section gives the model.

### 6.1 Layers and files

| Location | Scope | Committed |
|---|---|---|
| `<repo>/.devhub/` | the project; shared with teammates | yes (the team decides) |
| `~/.devhub/projects/<project folder name>/` | the user's additions for that project | no |
| `~/.devhub/` | global: scripts and actions for every project | no |

Inside each: `project.json` (only in the project layers), `actions/*.json`, `scripts/*` (executables with a header), `tabs/*.json`. Items merge by `id`; the user layer wins over the project layer, the project layer wins over global.

The app watches these folders (`DispatchSource` on the directories) and reloads on change. A broken file shows an inline error with the file name and the reason; the other files still load.

### 6.2 `project.json`

Describes how the project builds and runs. Everything is optional; missing values are detected.

```json
{
  "name": "My App",
  "kind": "xcode",
  "xcode": { "container": "MyApp.xcworkspace", "scheme": "MyApp", "configuration": "Debug", "bundleID": "com.example.myapp" },
  "build": { "command": "Scripts/build-sim.sh" },
  "run": { "command": "Scripts/run-sim.sh" },
  "git": {
    "baseBranch": "origin/main",
    "commitPrefix": { "pattern": "^([A-Z]+-\\d+)", "format": "$1: " },
    "worktrees": { "folder": ".worktrees", "include": [".env", "Config/Local.xcconfig"], "bootstrap": "Scripts/bootstrap.sh", "bootstrapMarker": "Pods" }
  },
  "launch": { "profiles": [ { "id": "staging", "title": "Staging", "env": { "API_ENV": "staging" }, "args": ["-ui-testing"], "defaults": [ { "suite": "group.com.example.myapp", "key": "environment", "value": "staging" } ] } ] },
  "logs": { "process": "MyApp", "subsystem": "com.example.myapp" },
  "simulators": { "statusScript": "scripts/sim-status.sh" },
  "home": { "quickActions": ["builtin.buildRun", "builtin.runAttach", "clean-derived-data", "builtin.terminal"] }
}
```

- `kind`: `xcode` (default when a workspace or project is found) or `command`. With `command`, Build & Run runs `build.command` then `run.command` with the context variables (6.3) instead of `xcodebuild`; the simulator list and the rest of the tab still work. Use this for a project that cannot be built in the generic way, and to run a project through any executable file.
- `xcode.container`: when missing, the first `.xcworkspace`, else the first `.xcodeproj` in the folder. `scheme`: when missing, the first shared scheme. `bundleID`: when missing, the shortest `PRODUCT_BUNDLE_IDENTIFIER` in the `.pbxproj` that does not contain `Tests`, `Extension`, `Widget`, `Clip` or `$`. The bundle ID of a built app always comes from the built `Info.plist`.
- `git.baseBranch`: when missing, `refs/remotes/origin/HEAD`, else `origin/main`.
- `git.worktrees.folder`: relative to the repo. When missing: a sibling folder `<repo>-<branch>` next to the repo. Slashes in branch names become dashes. `include` lists files copied into a new worktree (gitignored config files). `bootstrap` runs when `bootstrapMarker` exists in the main checkout and is missing in the worktree.

### 6.3 Actions

One JSON file per action, or several in one file. An action is a button somewhere in the UI that runs something.

```json
{
  "id": "clean-derived-data",
  "title": "Clean DerivedData",
  "subtitle": "Removes the DerivedData folder of this project",
  "icon": "trash",
  "tint": "red",
  "placements": ["home.quickActions", "git.pills"],
  "run": { "script": "scripts/clean-derived-data.sh" },
  "cwd": "checkout",
  "inputs": [ { "key": "branch", "title": "Branch", "type": "branch", "default": "current", "remember": true } ],
  "confirm": "Delete DerivedData for this project?",
  "refresh": ["worktrees"]
}
```

- `run` is one of: `{ "script": "<path relative to the .devhub folder>" }`, `{ "command": ["git", "fetch", "--prune"] }`, `{ "terminal": "make lint" }` (opens the terminal and runs the text there), `{ "open": "https://ci.example.com/{branch}" }` (URL or path; placeholders from the context).
- `cwd`: `checkout` (the checkout chosen in the Git tab, default), `main` (main checkout), `project` (the project folder), or a path.
- `inputs[].type`: `text`, `number`, `toggle`, `choice` (with `options`), `branch`, `worktree`, `simulator`, `scheme`, `file`, `folder`. Pickers are searchable. `remember: true` keeps the last value per project. Values reach the script as `DEVHUB_INPUT_<KEY>` and as `{key}` placeholders.
- `placements`: `home.quickActions`, `home.scripts`, `git.pills`, `git.branchRow`, `worktrees.row`, `simulators.runBar`, `simulators.row`, `logs.toolbar`, `palette` (always included), and `tab.<tabID>` for custom tabs. A row placement gets the row's item in the context (`DEVHUB_BRANCH`, `DEVHUB_WORKTREE_PATH`, `DEVHUB_SIMULATOR_UDID`).
- `confirm`: inline confirmation text inside the row or tile. No alerts.
- `refresh`: stores to refresh after success: `git`, `worktrees`, `simulators`, `scripts`, `logs`.
- `when` (P1): visibility conditions, for example `{ "git": "dirty" }`, `{ "simulator": "booted" }`, `{ "tool": "gh" }`.

**Context variables** given to every script and command (also usable as `{name}` placeholders in `open`, `terminal` and `command` strings):

`DEVHUB_PROJECT_PATH`, `DEVHUB_PROJECT_NAME`, `DEVHUB_CHECKOUT_PATH`, `DEVHUB_MAIN_PATH`, `DEVHUB_BRANCH`, `DEVHUB_BASE_BRANCH`, `DEVHUB_SCHEME`, `DEVHUB_CONFIGURATION`, `DEVHUB_BUNDLE_ID`, `DEVHUB_SIMULATOR_UDID`, `DEVHUB_SIMULATOR_NAME`, `DEVHUB_APP_PATH` (last built app, may be empty), `DEVHUB_WORKTREE_PATH` (row placements), `DEVHUB_INPUT_<KEY>`, `DEVHUB_CONFIG_DIR` (the folder of the action's file), `DEVHUB_VERSION`.

### 6.4 Scripts

Any executable file under `scripts/` is an action with placement `home.scripts` without a JSON file. The header lines define it:

```sh
#!/bin/zsh
# devhub: title = Regenerate resources
# devhub: subtitle = Runs the resource generator after asset changes
# devhub: icon = wand.and.stars
# devhub: tint = purple
# devhub: input = target, Target, choice, App|Widget
# devhub: input = clean, Clean first, toggle, false
# devhub: placements = home.scripts, git.pills
# devhub: confirm = This takes a minute. Continue?
```

The file name is the fallback title. Only executable files count; a non-executable file shows a row with "chmod +x" as the hint.

### 6.5 Script line protocol (a script drives the UI)

Lines that start with `@devhub ` followed by one JSON object are directives. Every other line is plain output for the Output panel.

| Directive | Effect |
|---|---|
| `{"progress": "Compiling", "fraction": 0.4}` | footer and run bar step text; `fraction` optional |
| `{"toast": "Done"}` | toast |
| `{"copy": "text"}` | copies to the clipboard and shows a toast |
| `{"open": "https://…"}` or a path | opens with the default app |
| `{"notify": "Build finished", "body": "…"}` | system notification when the panel is closed (P2) |
| `{"refresh": ["git", "simulators"]}` | refreshes stores |
| `{"error": "message"}` | marks the run as failed with this message even with exit 0 |
| `{"view": { "rows": [ { "id": "…", "title": "…", "subtitle": "…", "tags": [{"text": "ok", "tint": "green"}], "actions": [ { "title": "Open", "run": { "open": "…" } } ] } ] }}` | replaces the result area of the action (a custom tab section, or the Output entry) with rows that have their own actions |
| `{"view": { "keyValues": [ ["Version", "1.2"], ["Build", "345"] ] }}` | a key-value block |

`simulators.statusScript` uses the same protocol: it receives `DEVHUB_SIMULATOR_UDID` and `DEVHUB_BUNDLE_ID`, prints one `{"view": {"keyValues": …}}` or a plain line, and the row shows it under the device name. The app runs it for booted, favourite and target simulators, caches the result and runs it again after a launch.

### 6.6 Custom tabs

```json
{
  "id": "qa",
  "title": "QA",
  "icon": "wrench.and.screwdriver",
  "searchPrompt": "Search QA tools",
  "sections": [
    { "title": "Accounts", "actions": ["login-as-tester", "reset-account"] },
    { "title": "Devices", "source": { "script": "scripts/list-devices.sh", "refresh": "onOpen" } }
  ]
}
```

A section lists actions (rendered as rows with inputs) or a `source` script whose `{"view": …}` output renders rows. The tab joins the tab bar after the built-in tabs, gets a ⌘ number and the header search.

---

## 7. Architecture

### 7.1 Layers and folders

```
DevHub/
  App/          DevHubApp.swift (@main, Settings scene only), AppDependencies.swift (composition root), AppEvents.swift
  Core/         Models/ (value types), Config/ (schema types, decoding, merge), Parsers/ (pure functions), LogRedactor.swift
  Services/     ShellRunner.swift, CommandLog.swift, Providers.swift (bundle of protocols, .mock and .live)
                Git/ Xcode/ Simulators/ Logs/ AI/ Config/ Scripts/ Workspace/
  Shared/       ProjectSession, Navigator, ActivityLog, Toaster, OutputPanelState, SettingsStore, WindowLayout, WorkspaceActions, ActionCatalog
  Features/<Name>/   <Name>Store.swift and one file per view (screen, toolbar, row, panel)
  Shell/        AppWindows, RootView, HeaderView, FeatureTabBar, FooterView, ProjectMenu, SearchFilterBar, WindowDragArea, ResizeGrip, CommandPalette
  UI/           Theme, Components, ActionBar, FlowLayout, Hint, CopyOnClick, SearchablePicker, WindowAppearance, FolderPicker
Scripts/        build.sh run.sh install.sh make-launcher.sh ai/
docs/           SPEC.md STATUS.md extensions.md examples/
```

Dependency direction, strict: `App → Shell → Features → Shared → Services → Core`.

- `Core` imports Foundation only. No AppKit, no SwiftUI, no `Process`. Everything here works on plain values, so a parser can be checked in a preview or a playground without the app.
- `Services` run commands and read files. They expose protocols (`GitRepositoryProviding`, `SimulatorProviding`, `BuildProviding`, …) with a `Mock…` and a `Live…` type each, collected in the `Providers` bundle. Only `Services/Workspace/` may import AppKit (openers, hot key, Accessibility).
- `Shared` holds app-wide state with no feature logic.
- `Features` hold one `@MainActor @Observable final class <Name>Store` per feature plus its views. A store receives its provider and the lower stores it reads through `init`. Stores never import SwiftUI; a tint is an enum in `Core`, mapped to `Color` in `UI`.
- `Shell` and `UI` know nothing about features except through `FeatureRegistry` and the environment.
- `AppDependencies` builds every store once and injects them with `.environment`. `AppDependencies.mock()` feeds previews.

### 7.2 Rules

- **Stores depend one way.** `Shared ← Worktrees, Simulators, Usage, Sessions ← Git ← Build`. A lower store never knows a higher one. Cross-feature actions are wired in views (a Git row's "Run on target" calls `navigator.show("simulators")` then `build.run(branch:)`).
- **Events instead of calls.** When a store changes data that other features show, it posts an `AppEvent` (`projectChanged`, `branchesChanged`, `worktreesChanged`, `simulatorsChanged`, `configChanged`, `commandFailed`). Interested stores subscribe in `init`. Add a case only when a second store needs to react.
- **Views mutate only their own `@State`.** Every data mutation is a store method. Async work lives in stores (`Task`), never in views.
- **Providers return values or streams.** Long work returns `AsyncThrowingStream` of events; cancelling the consuming task terminates the process.
- **Every command through `ShellRunner`.** Never `Process` directly. Never on the main actor.
- **Every failure is visible.** An `ActivityEvent` with `.failure`, the Output panel opens, no silent `catch`.
- **No comments in code.** Names and small functions carry the meaning. `// MARK: -` for sections only.
- **Persistence**: `UserDefaults` through one `AppPreferences` type with named keys; JSON-encoded structs for anything beyond a scalar. Config files are the user's; the app never writes into `.devhub/` except "Create example".
- **No tests.** The build with zero warnings and a manual run are the check. A parser is checked by running the real command once in the Output panel and comparing with what the screen shows.

### 7.3 Swift conventions

- `guard` for early exit. `== false` instead of `!`.
- `[weak self]` closures start with `guard let self else { return }` on its own line, then no `self.`.
- Member order: environment and dependencies, `let` inputs, `@State`, `body`, private computed properties, private functions.
- Default parameter values only for cosmetic view inputs and `@ViewBuilder` closures.
- One concern per `extension`. Multi-line calls: first argument on a new line, closing `)` on its own line.
- Types that must run off the main actor are `actor` or `nonisolated` (default isolation is `MainActor`).

### 7.4 UI conventions

- Horizontal padding 14. Row vertical padding 7 to 8. Dividers between rows inset 56 from the left so they align with the text, not the icon.
- Rows reveal actions on hover with `opacity`, never with a layout change. Selected rows keep their actions visible. Right-click shows the same actions in a context menu.
- Destructive actions confirm inline inside the row: the row grows by one line with the consequence text, Cancel and a red button. No alerts, no sheets (they are unreliable inside a menu bar panel).
- Every icon without text has a hover hint (`.hint`), never `.help` (8.3). Buttons never get cut: `.fixedSize()`, long rows in `ActionBar`, tag rows in `FlowLayout`, cut text gets `.hintWhenTruncated`.
- Static text a user may paste (paths, branches, hashes, IDs) gets `.copyOnClick(value, label:)`. Copy buttons call `toaster.copy`. Never write to `NSPasteboard` outside `Toaster`.
- Light scheme forced on the panel window. Near-white `Theme.base` for chrome, white `Theme.surface` for cards and lists, hairline `Theme.border`, `Theme.hover`. Accent colour for selection. Semantic tints: green clean/success/booted, orange dirty/booting, red missing/failure/destructive, blue current/target/branch, purple merged/scripts, indigo project. No hex colours outside `Theme`.
- Monospaced font for paths, file names, hashes and commands.
- Shared components (`UI/Components.swift` and friends): `Tag`, `IconTile`, `IconButton`, `OverflowMenu`, `PanelCard`, `SectionHeader`, `SearchField`, `StatusDot`, `ActionBar`, `FlowLayout`, `SearchablePicker`, `InlineConfirm`, `KeyValueBlock`, `EmptyState`. Check the list before writing a new element; a new shared block goes into `UI/` and into the `ui-components` skill.
- `SearchablePicker`: a button that shows the current value and opens a popover with a search field and a list; arrows and Return select; Esc closes; shows a detail column (for example "local · has a checkout"); caps the list at 200 rows and says how many are hidden.

---

## 8. Technical playbook (verified solutions and traps)

### 8.1 Menu bar item and panel

- **Do not use `MenuBarExtra(.window)`.** It puts the panel back under the icon on every open and every resize, so a saved position never holds, and its window cannot be moved. Use an `NSStatusItem` plus an own borderless `NSPanel` subclass (`canBecomeKey` true, `isFloatingPanel`, `level = .statusBar`, `hidesOnDeactivate = false`, `isReleasedWhenClosed = false`, `collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]`, `animationBehavior = .none`, `isMovable = false`, clear background with its own rounded clip and shadow). The SwiftUI app body is `Settings { EmptyView() }` only; `AppDependencies.live()` creates `AppWindows`, which owns the status item, the panel and the pinned window.
- **Open at once.** Create the hosting controller on the first open and keep it; later opens only set the frame and `makeKeyAndOrderFront`. Increment an `openCount` the root view uses as `.task(id:)` to refresh stores on each open.
- **Close rules.** A global mouse-down monitor (`NSEvent.addGlobalMonitorForEvents`) and `NSApplication.didResignActiveNotification` close the panel. Remove the monitor on close.
- **Position.** `WindowLayout` keeps `size` and `panelTopLeft` in `UserDefaults`. `panelFrame(anchor:screen:)` clamps the frame 12 points inside `visibleFrame` of the screen that contains the top-left point, shrinks the size when the screen is smaller, and writes the clamped point back. Move by an `NSView` that overrides `mouseDown` / `mouseDragged` and sets `window.setFrameOrigin` itself (`mouseDownCanMoveWindow` false). Save the top-left corner on mouse up. The resize grip sets the frame from the saved top-left corner, so a moved panel does not jump back.
- **Pinned window.** `NSWindow` with `level = .floating`, `setFrameAutosaveName`, the same root view with `isPinnedWindow` in the environment; `NSHostingController.sizingOptions = [.minSize]` so the window resizes by its edges.
- **Light appearance.** `preferredColorScheme` does not reach an AppKit panel. Set `window.appearance = NSAppearance(named: .aqua)` from an `NSViewRepresentable` inside the view tree (`WindowAppearance`) and add `.colorScheme(.light)`. Never set `NSApp.appearance`: the menu bar icon label would turn black on a dark menu bar.
- **Dock icon toggle**: `NSApp.setActivationPolicy(.regular / .accessory)`. **Launch at login**: `SMAppService.mainApp.register()`; status `requiresApproval` means open System Settings → Login Items.
- **Global shortcut**: Carbon `RegisterEventHotKey` with `InstallEventHandler(GetApplicationEventTarget(), …)`; needs no Accessibility permission. The handler posts a `Notification` to the main queue. A fixed list of shortcuts (⌥⌘D, ⌃⌥Space, ⌃⌥D) is enough; a recorder is P2.
- **Ad-hoc signing and permissions.** Each rebuild changes the binary; macOS may ask for Accessibility again. Show a clear activity line with the System Settings path.

### 8.2 Hints

The system `.help` tooltip is slow and often does not appear in a menu bar panel. `HintCenter` holds the current hint; a `.hint(_:)` modifier reports its global frame with `onGeometryChange` and shows after 0.55 s (0.06 s while moving between items); `HintOverlay` draws one bubble in an overlay of the root view, placed below the item or above when there is no room, capped at 260 points wide. A local event monitor hides the hint on click, key or scroll. `hintWhenTruncated` measures the ideal width with a hidden `fixedSize()` copy in the background.

### 8.3 `ShellRunner`

- One `actor ShellRunner` with `run(executable, arguments, cwd, environment) -> ShellResult` and `stream(executable, arguments, cwd, onLine) -> exitCode`. Launch through `/usr/bin/env <executable>` so the user's `PATH` applies; prepend `/opt/homebrew/bin` and `/usr/local/bin`.
- **Deadlock trap.** Blocking pipe reads on the Swift concurrency pool with a reader on a global GCD queue hang when 30+ commands run in parallel (the whole simulator refresh froze). Run the blocking read on a **dedicated concurrent `DispatchQueue`** and read stderr on that queue too while stdout is read; then `waitUntilExit`.
- **Streaming.** `process.standardOutput = process.standardError = pipe`; `for try await line in pipe.fileHandleForReading.bytes.lines`; wrap in `withTaskCancellationHandler` whose `onCancel` calls `process.terminate()`. After the loop `try Task.checkCancellation()`: a cancelled stream ends without throwing.
- **Recording.** Every run sends `started / output / finished` events to `CommandLog` (main actor) through a FIFO hop on the main queue; streamed output is batched every 0.25 s. Commands are classified: `read` (git status, log, for-each-ref, rev-parse, diff, simctl list, listapps, get_app_container, du, ps, grep, xcodebuild -showBuildSettings, gh/glab api), `action`, `secret` (`security`), `appLog` (`simctl spawn … log`). Secret and appLog never record output.
- Child processes of `simctl launch` get environment through `SIMCTL_CHILD_<NAME>` variables.
- `open -a <App> <path>` for Finder, Xcode and terminals. Ghostty needs `open -na Ghostty --args --working-directory=<path>`. To run a command in a terminal, write a temporary `.command` script (`rm -f "$0"`, `cd`, `exec "${SHELL:-/bin/zsh}" -i -l -c "<command>; exec \"${SHELL:-/bin/zsh}\" -i -l"`), chmod 700, and open it with the terminal app (Ghostty: `-e <script>`).

### 8.4 Git and worktrees

| Need | Command | Note |
|---|---|---|
| Worktrees | `git worktree list --porcelain` | blocks: `worktree`, `HEAD`, `branch refs/heads/…`, `locked`, `prunable`; the first block is the main checkout |
| Status | `git status --porcelain=v2 --branch` | `# branch.oid`, `# branch.head` (`(detached)`), `# branch.upstream`, `# branch.ab +1 -0`; other lines are changed files |
| Changed files | `git status --porcelain=v1 -z --untracked-files=all` | `-z`: a renamed entry is followed by its original path as the next NUL field |
| Branches | `git for-each-ref refs/heads --format='%(refname:short)%09%(upstream:short)%09%(upstream:track,nobracket)%09%(committerdate:unix)%09%(worktreepath)%09%(contents:subject)'` | `track` is `gone`, `ahead N`, `behind N` or both |
| Remote branches | `git for-each-ref refs/remotes/origin --sort=-committerdate --format=…` | skip `origin/HEAD` |
| Last visit | `git reflog show --format='%gs%x09%ct' -n 3000 HEAD` | lines `checkout: moving from A to B` give the last visit of B |
| Merged | `git branch --merged <base> --format='%(refname:short)'` | see the rule below |
| Base branch | `git symbolic-ref --short refs/remotes/origin/HEAD` | fallback `origin/main`; configurable |
| Distance to base | `git rev-list --left-right --count HEAD...<base>` | |
| Not pushed commits | `git rev-list -n 150 HEAD --not --remotes=origin` | marks only commits that are on no remote branch; "no upstream" alone does not mean unpushed |
| Operation in progress | `git rev-parse --git-path rebase-merge` / `rebase-apply` / `MERGE_HEAD` / `CHERRY_PICK_HEAD` and check existence | |
| Last fetch | mtime of `<git-common-dir>/FETCH_HEAD` | |
| Web URL | `git remote get-url origin` → `git@host:group/repo.git` → `https://host/group/repo` | GitHub paths `/tree/<b>`, `/compare/<base>...<b>?expand=1`; GitLab `/-/tree/<b>`, `/-/merge_requests/new?merge_request[source_branch]=…` |
| Update without switching | `git fetch origin <branch>:<branch>` | fails on non-fast-forward, which is wanted; a branch checked out in a worktree gets `git pull --ff-only` inside that worktree |
| Continue rebase | `git rebase --continue` with `GIT_EDITOR=true` | |
| Create worktree | `git worktree add <path> <branch>` (local), `git worktree add --track -b <b> <path> origin/<b>` (remote), `git worktree add --no-track -b <b> <path> <base>` (new) | validate the name first with `git check-ref-format --branch <name>` |
| Remove worktree | `git worktree remove <path>`, `--force --force` only when dirty or locked and the user confirmed | branch with `git branch -d` only, never `-D` without the second inline confirm |

Rules learned:
- **"Merged" needs a pushed branch.** A new branch with no commits is technically merged into the base. Treat a branch as merged only when its upstream is `origin/<same name>` and `ahead == 0`. Without this rule Clean Finished deletes fresh worktrees.
- Clean Finished skips dirty, locked, missing worktrees and the current build source.
- A branch merged with a squash is not detected as merged until the remote branch is deleted and Fetch runs. Document it, do not try to detect squashes.
- `git branch --merged` needs the base to exist locally as a remote ref; after a fresh clone run Fetch first.
- Every git action refreshes the Git state and posts `branchesChanged`; the Worktrees store listens.

### 8.5 Xcode builds and simulators

Build pipeline for `kind: xcode`:

1. `xcrun simctl boot <udid>` (exit code **149** means "already booted" and counts as success; same for shutdown).
2. `xcodebuild clean` when Fast is off.
3. `xcodebuild -workspace|-project <container> -scheme <s> -configuration <c> -destination id=<udid> ONLY_ACTIVE_ARCH=YES build`, streamed. **No `-derivedDataPath`**: sharing Xcode's DerivedData reuses the cache of the Xcode build of the same checkout.
4. Locate the `.app`: first from `Touch`, `Validate`, `CodeSign` or `RegisterExecutionPolicyException` lines of the output that end with `.app` under `<Configuration>-iphonesimulator/`; else from the DerivedData folder whose `info.plist` has `WorkspacePath` equal to the container (compare case-insensitively, standardize paths) under `Build/Products/<Configuration>-iphonesimulator`; last resort `xcodebuild -showBuildSettings -json` (slow, about 30 s on a large project) and `TARGET_BUILD_DIR/WRAPPER_NAME` of the entry with `PRODUCT_TYPE == com.apple.product-type.application`. Bundle ID from the app's `Info.plist` (`CFBundleIdentifier`).
5. Clean install when asked: `simctl terminate`, `simctl uninstall`, `simctl keychain <udid> reset`.
6. `xcrun simctl install <udid> <app>`; `open -a Simulator --args -CurrentDeviceUDID <udid>`; `xcrun simctl launch --terminate-running-process [--wait-for-debugger] <udid> <bundleID> [args]` with `SIMCTL_CHILD_*` environment. The launch output `…: <pid>` gives the PID.

Traps:
- **Never pass `CODE_SIGNING_ALLOWED=NO`** (or other signing overrides) to a build that will run. It skips the ad-hoc signature of embedded frameworks, and dyld on Apple silicon refuses unsigned code even in the simulator: the app dies at launch with "Library not loaded: @rpath/<Framework>". Let `xcodebuild` sign for a simulator destination the way Xcode does.
- **Progress is indeterminate.** `xcodebuild` reports no total. Show a bar without a value and a step text: the verb from the first token of the line (`SwiftCompile`, `CompileC`, `Ld`, `CodeSign`, `PhaseScriptExecution`, `CompileAssetCatalog`, `CopySwiftLibs`, `ProcessInfoPlistFile`, `Touch`, `Validate` …) mapped to a word, plus the target from `(in target '…')`. The first `error:` line becomes the failure message. Do not fake a percentage.
- **DerivedData root** respects `IDECustomDerivedDataLocation` from `com.apple.dt.Xcode` preferences (`CFPreferencesCopyAppValue`); a relative value is under the home folder. Delete a DerivedData folder only when its path is under that root. Size with `du -sk`.
- **Schemes**: names of `.xcscheme` files under `<container>/xcshareddata/xcschemes` and `<container>/xcuserdata/*/xcschemes`; for a workspace also in sibling `.xcodeproj` folders. Fall back to the configured scheme when no file is found.
- **Simulator list**: `xcrun simctl list devices available -j`; `devices` is keyed by runtime identifier (`com.apple.CoreSimulator.SimRuntime.iOS-26-4`), each device has `udid`, `name`, `state` (`Booted`, `Shutdown`, `Booting`, `Shutting Down`), `deviceTypeIdentifier`, `isAvailable`. Sort runtimes by version, newest first; phones before pads.
- **Installed app count** without booting: count folders under `~/Library/Developer/CoreSimulator/Devices/<udid>/data/Containers/Bundle/Application`.
- **App containers on a shut-down simulator**: `simctl get_app_container` fails. Scan `…/data/Containers/Bundle/Application/*/` and `…/data/Containers/Data/Application/*/` for `.com.apple.mobile_container_manager.metadata.plist` whose `MCMMetadataIdentifier` equals the bundle ID.
- **User apps**: `simctl listapps <udid>` (plist text) filtered by `ApplicationType == User`; uninstall each. A shut-down device is booted first (`boot`, then `bootstatus`), cleaned, shut down again. Many devices take minutes; run one at a time with progress and Stop.
- **Defaults in the app container**: when booted, `xcrun simctl spawn <udid> defaults write <path to Library/Preferences/<suite>.plist> <key> -string <value>`; when shut down, read and write the plist with `PropertyListSerialization` (binary format).
- **Clean install without a build**: keep a copy of the installed `.app` (`ditto`) under `~/Library/Caches/DevHub/Apps/<udid>-<bundleID>.app` and reinstall from it; fall back to the last built product.
- **Run & Attach**: Xcode has no CLI to attach. `open -a Xcode <container>`, wait for a window (`System Events` window count, up to 150 s on a cold start plus a 6 s settle), select the run destination by UDID through Xcode's AppleScript dictionary (`run destinations` of the `workspace document`), then `System Events`: click menu item "Attach to Process by PID or Name…" in the Debug menu, **set the value** of the sheet's text field (keystrokes do not reach it), click Attach. Confirm within 25 s that the process left the stopped state (`ps -o stat= -p <pid>` no longer starts with `T`); else report the PID and the manual steps. Needs Accessibility (`AXIsProcessTrusted`, prompt with `AXIsProcessTrustedWithOptions`) and the Apple Events usage description in `Info.plist`. The menu item name is the contract with Xcode; a renamed item breaks the attach.
- **Deep link / push**: `simctl openurl <udid> <url>`; `simctl push <udid> <bundleID> <file.apns>` with a JSON body that has an `aps` key.
- **Build source from a branch**: when the branch has no checkout, create the worktree first (section 6.2 rules), run the bootstrap when the marker says so, then build inside that path. The main checkout never changes.
- One build at a time; Cancel terminates `xcodebuild` and leaves the state `idle`.

### 8.6 `kind: command` projects

`build.command` and `run.command` are executables run from the project folder with the context variables (6.3). Their output streams to the Output panel and the footer through the line protocol (6.5). When `run.command` prints `@devhub {"app": "/path/App.app"}` the app uses that path for install and launch; otherwise the script is responsible for the launch. This covers projects with a custom build system and projects that are not Xcode projects at all.

### 8.7 Logs

- `xcrun simctl spawn <udid> log stream --style ndjson --level debug --predicate 'process == "<Executable>"'` (or `subsystem == "…"`). Each line is a JSON object with `timestamp` (`yyyy-MM-dd HH:mm:ss.SSSSSSZ`), `messageType` (`Debug`, `Info`, `Default`, `Error`, `Fault`), `subsystem`, `category`, `eventMessage`.
- Only `os_log` / `Logger` lines arrive. `print()` output does not reach the system log; say so in the empty state.
- The executable name comes from the installed app's `Info.plist` (`CFBundleExecutable`) through `simctl get_app_container <udid> <bundleID> app`.
- **Redaction before storage**: mask `Bearer <token>`, JWTs (`eyJ…`.`…`.`…`), and values after keys `authorization`, `x-auth-token`, `access_token`, `refresh_token`, `id_token`, `token`, `password`, `secret`, `api_key` (case-insensitive, `:` or `=`). Lines stay in memory only. The stream's `CommandLog` entry hides output.
- Batch incoming lines every 150 ms; cap 5 000 lines per stream with a dropped counter; pause keeps a pending queue with a count.
- A stream that exits with a non-zero code reports "Is the simulator still booted?".

### 8.8 Projects and detection

- A project is a folder. Detection: `.xcworkspace` first, else `.xcodeproj`; schemes from files; bundle ID from `.pbxproj` as in 6.2; git repository when `.git` exists (file or folder). `kind: command` when `.devhub/project.json` says so.
- Projects, the selected project, settings and per-simulator run options live in `UserDefaults` as JSON. The selected tab, Logs choices, AI scope, favourites and the target simulator survive a relaunch.
- Loading saved values must not write defaults back over them (guard with an `isLoading` flag around `didSet` persistence).

### 8.9 AI sessions

**Copilot CLI** (`~/.copilot/session-state/<uuid>/`):
- `workspace.yaml`: flat `key: value` lines: `id`, `cwd`, `git_root`, `branch`, `client_name`, `name` (optional, set by the CLI or the user), `summary` (optional), `user_named`, `summary_count`, `created_at`, `updated_at` (ISO 8601 with milliseconds, `Z`). A 30-line parser is enough; no YAML library.
- `events.jsonl`: one JSON object per line with `type`. Use `user.message` → `data.content` (first one as the fallback title, last one as "last prompt"). Skip the rest. A session folder without `events.jsonl` was never used; skip it.
- Files `<uuid>.jsonl` next to the folders are exports; ignore them. `session-store.db` is SQLite with WAL; do not read it. `~/.copilot/config.json` is not plain JSON; do not parse it.
- Resume: `cd <cwd> && copilot --resume <id>`. `copilot --continue` resumes the most recent one. The installed CLI (`copilot sessions`) has no `list` subcommand; listing from disk is the only way.
- Title precedence: `name`, else `summary`, else the first user message, else the folder name.

**Claude Code** (`~/.claude/projects/<cwd with slashes as dashes>/<uuid>.jsonl`):
- Scan lines by prefix without decoding every line: `{"type":"custom-title"` → `customTitle`, `{"type":"ai-title"` → `aiTitle`, `{"type":"last-prompt"` → `lastPrompt`, and the first object that has `cwd` (also `gitBranch`, `timestamp`). Title precedence: custom, AI, last prompt. Skip files without `cwd`. Files are large: cache the parsed result per file keyed by modification date.
- Resume: `cd <cwd> && claude --resume <id>`.

Both: group by day of `updatedAt`, newest first; scope "This project" filters by `cwd` equal to or under the project folder; collapse titles to one line, cap at 300 characters.

### 8.10 Claude usage

- Token: `security find-generic-password -s "Claude Code-credentials" -w` (the plain service name, not the ones with a hash suffix) gives JSON `{"claudeAiOauth": {"accessToken", "refreshToken", "expiresAt" (ms), "subscriptionType"}}`; fallback file `~/.claude/.credentials.json`. The `security` binary is already allowed on that item, so no permission dialog.
- `GET https://api.anthropic.com/api/oauth/usage` with `Authorization: Bearer <token>`, `anthropic-beta: oauth-2025-04-20`, `Accept: application/json`. Response keys `five_hour`, `seven_day`, `seven_day_<model>` each `{ "utilization": 0-100, "resets_at": ISO 8601 }`; ignore `seven_day_oauth_apps`; accept unknown keys with the same shape.
- **Never refresh the token.** Refreshing rotates the refresh token and can log Claude Code out. An expired token shows "Run `claude` once." The endpoint is undocumented; parse tolerantly and show a Retry.
- The command is classified `secret`; nothing of it is recorded or logged.

### 8.11 Copilot usage

- Token: Copilot CLI stores its GitHub OAuth token in the login keychain under the generic password service `copilot-cli` (`security find-generic-password -s copilot-cli -w`). Verify the value format once in the session (`| head -c 4` prints `gho_` for a plain token; if it prints `{`, the value is JSON and the token is a field inside). Fallback: `gh auth token` when the GitHub CLI is installed and logged in. Classified `secret`.
- `GET https://api.github.com/copilot_internal/user` with `Authorization: token <token>` and `Accept: application/json`. Response: `quota_snapshots` with `premium_interactions` (`entitlement`, `remaining`, `percent_remaining`, `unlimited`, `overage_permitted`), also `chat` and `completions`; `quota_reset_date`; `copilot_plan`. Show premium requests used (`entitlement - remaining`), percent, reset date, plan. `unlimited: true` or a missing quota (free plan) hides the bar and shows the plan name only.
- Undocumented endpoint; GitHub may change it. Tolerant parser, inline error with Retry, never a crash. Enterprise hosts are out of scope.

### 8.12 Pull and merge requests

- GitHub: `gh pr view <branch> --json number,state,isDraft,url,mergeable,reviewDecision,statusCheckRollup,baseRefName` (exit code 1 with "no pull requests found" means none). GitLab: `glab api --hostname <host> projects/<url-encoded path>/merge_requests?source_branch=<b>&state=all&order_by=updated_at&per_page=5` and `…/pipelines?ref=<b>&per_page=1`. Both are read-only `api`/`view` calls classified `read`; the app never reads or stores a token.
- Not installed: "brew install gh" / "brew install glab". Not logged in: the login command with the host, with a copy button. Load on demand (when the Git tab shows), cache per branch for 60 s.

### 8.13 Build scripts

- `Scripts/build.sh [Debug|Release]`: `xcodebuild -project DevHub.xcodeproj -scheme DevHub -configuration <c> -destination 'platform=macOS' -derivedDataPath DerivedData -quiet build`, prints the `.app` path. With `-quiet` any output other than the path is a warning or an error and must be fixed.
- `Scripts/run.sh`: Debug build, `pkill -x DevHub`, `open <app>`. `Scripts/install.sh`: Release build copied to `/Applications/DevHub.app`. `DevHub.command` in the repo root calls `run.sh` so the app starts from Finder with a double click. `Scripts/make-launcher.sh` compiles a small AppleScript app (`osacompile`) that calls `run.sh` and shows an alert when the build fails.
- Headless smoke check after a build: start the binary inside the `.app`, wait 3 s, `kill -0` confirms it is alive, then kill it.
- Common failures: scheme not found → open the project once in Xcode; nothing visible after launch → it is a menu bar app, look for the icon, `pgrep -x DevHub`; two icons → two instances, `pkill -x DevHub`; "resource fork, Finder information, or similar detritus not allowed" → `xattr -cr DevHub/`.

---

## 9. Documentation duties of the agent

The repo is the memory between sessions. Four files and the skills carry it.

| File | Content | When |
|---|---|---|
| `AGENTS.md` | project facts, layout, conventions, build commands, the rules in section 7 in short form. `CLAUDE.md` imports it with `@AGENTS.md`. | whenever a folder, a convention or a command changes |
| `CHANGELOG.md` | Keep a Changelog format; `[Unreleased]` collects the session: Added, Changed, Fixed, Removed, Infrastructure; one line per user-visible change, described as behaviour, not as files | before every commit; the agentStop / Stop hook blocks a session that changed code without touching it |
| `docs/STATUS.md` | stage, what is real and what is mock per screen, decisions that must not be undone (numbered, with the reason), next steps, known gaps | at the end of every milestone |
| `docs/extensions.md` | the config schema; must match the decoder | whenever a field is added or renamed |
| `.github/skills/*/SKILL.md` | how to add a feature, the UI components, the provider pattern, the Xcode toolchain traps, the panel window, extensions, build and run, update docs | whenever the thing a skill describes changes |

Hooks: `.github/hooks/devhub.json` (Copilot) and `.claude/settings.json` (Claude Code) run `Scripts/ai/session-brief.sh` at session start (recent commits, uncommitted changes, `[Unreleased]`, `docs/STATUS.md`) and `Scripts/ai/check-changelog.sh` when the agent stops (blocks when code changed without a changelog entry).

---

## 10. Acceptance checklist

- [ ] `Scripts/build.sh` prints only the app path; the app launches and stays alive.
- [ ] The panel opens from the menu bar in under a second with the last tab, moves, resizes, pins, remembers its place.
- [ ] Every tab filters by the header search; every picker with many items is searchable; ⌘K finds actions, tabs, simulators, branches and sessions.
- [ ] Every command appears in the Output panel; `security` output is hidden; log lines are masked.
- [ ] Home runs a script with an input from `.devhub/scripts`, and its `@devhub` directives drive the footer and toasts.
- [ ] Git: fetch, pull, push, force push with confirm, rebase on base, update base without switching, stash, switch, check out remote, delete, commit with prefix, commit and push, diff.
- [ ] Worktrees: list with states, create from local, remote and new, delete with DerivedData and branch, clean finished, bootstrap.
- [ ] Simulators: build and run the main checkout, a worktree and a branch with no checkout on any simulator with any scheme and configuration; launch profiles apply; Run & Attach attaches Xcode; clean install resets the keychain.
- [ ] Logs: two simulators stream at once, levels and search work, pause counts, nothing is written to disk.
- [ ] AI: Copilot and Claude sessions list, scope, resume in the terminal; usage strip shows both quotas or a clear message.
- [ ] Settings persist; launch at login works; the global shortcut opens the panel.
- [ ] Custom tab from `.devhub/tabs` appears; editing a config file reloads the UI.
- [ ] No project name, path, bundle ID or branch name in Swift. `grep -rn` for the owner's own project names returns nothing.
- [ ] `AGENTS.md`, `CHANGELOG.md`, `docs/STATUS.md`, `docs/extensions.md` and the skills match the code.
- [ ] Every finished feature is a commit that builds clean and launches; the commits are pushed to the remote when the remote accepts the push, so a clone of the remote at any moment runs.
- [ ] `README.md` of the new repo tells how to clone and run in three commands.

---

## Appendix A. Reference UI

Described from the earlier tool. Keep the structure; details may change.

- **Usage strip** (top, 36 points): "Claude" label, "Session" with a thin blue bar and "3%", "Week · all" with a bar and "33%", a chevron at the right. The new version adds a "Copilot" row: "Premium requests" bar with "37% · resets May 1".
- **Header**: a 36-point indigo icon tile with a cube symbol, the project name in bold, the branch name in small secondary text with an up/down chevron (opens the project menu). Right: a 260-point search field with a magnifier and a per-tab prompt ("Search branches, commits, files", "Search simulators", "Search log lines", "Search sessions", "Search actions and scripts"), a pin icon, a gear.
- **Tab bar**: pills with icon and title; the selected one is filled accent with white text. When space is short, unselected pills show only icons.
- **Home**: white project card (icon tile, name, path in monospaced text with a copy icon, blue branch tag, green "clean" tag, buttons Finder, Xcode, Terminal, Repository). "QUICK ACTIONS" section: a 4 × 2 grid of white tiles, each with a coloured 28-point icon tile, a semibold title and a one-line secondary subtitle. "SCRIPTS" section: header with the scripts folder path in monospaced text, a lightbulb, an open-folder icon and a plus; white list with rows (purple icon tile, title, description, "file.sh · ran yesterday", a Run button at the right).
- **Git**: a white header card. Top row: "Main checkout" picker with a folder icon and a chevron; right "fetched 2 hr. ago" and a refresh icon. Branch name large and semibold with the short hash in monospaced secondary text. A tag row: green "clean", orange "not pushed", blue "1 ahead of origin/main", grey "107 stashed". A PR line: "!1360 draft" tag and a green "pipeline success" tag with a refresh icon at the right. Pills row: Fetch, Pull (disabled when nothing to pull), Push, Force Push…, Rebase on main…, Update main, Pop Stash; at the right small icons for terminal, PR and web. Below the card a segmented control "Local 453 | Remote 200 | History | Changes" with a hint "Click a file to see its diff" at the right. Changes: a commit text box with the ticket prefix pre-filled, an "Amend" checkbox, "Stage files to commit" hint, "Commit & Push" and "Commit" buttons at the right (disabled when nothing is staged). Empty state: a check-circle icon, "No local changes", "The working tree of this checkout is clean."
- **Simulators**: a white run bar card. Row 1: scheme picker, configuration picker, source picker with a house icon and the branch name, "Fast" and "Clean install" checkboxes, a refresh icon at the right. "Target" label, then the device name in semibold with a runtime tag and the status line under it; at the right "Run & Attach" (bug icon) and a prominent blue "Build & Run". Then the launch profile row (segmented control of profiles) and the profile's fields. An info line explains what the next launch will do. Below the card: "119 simulators" with a blue "36 with apps" tag and "Remove Apps from All…" at the right. Sections "★ Favorites · 3 devices", "iOS 26.5 · 8 devices". Rows: green or grey dot, a phone icon, name in semibold, runtime tag, blue "target" tag, a yellow star, "Booted · 1 app installed", an optional status line; the target row has a light accent background and its icons visible: identity card, paper plane, play, remove-apps, power, ellipsis.
- **Logs**: toolbar with a simulator picker ("iPhone 17 Pro Max · iOS 26.5"), a monospaced process field, a blue "Start" button; a second row with the level segmented control "All | Info+ | Default+ | Errors" and "Pause", copy and trash icons at the right. Empty state: text-lines icon, "App logs", "Pick a booted simulator and press Start. Tokens and passwords in the lines are masked. Nothing is saved to disk." The new version adds a chip bar for several streams.
- **AI sessions**: toolbar "245 sessions", a segmented control "This project | All", a refresh icon. Day headers "Today", "Yesterday". Rows: an orange sparkle tile (Claude) or a blue tile (Copilot), the title, "Oct 9, 2026 at 10:50  ~/Projects/app" with the path in monospaced text, a blue branch tag, the last prompt in one secondary line, a "Resume" button with a terminal icon at the right.
- **Output panel**: a header row "Output · 1 commands", a search field "Search output", a "Show reads" checkbox, "Copy All", "Clear", a collapse chevron. Entries: a green check or red cross, "$ security find-generic-password -s 'Claude Code-credentials' -w" in monospaced text, "42 ms" and a copy icon at the right, then the output lines or "Output hidden: it contains credentials."
- **Footer**: "● Ready" (or a spinner with the build step) at the left; "⌄ Output", "⌘1–7 tabs", "Quit" and a resize grip at the right.

## Appendix B. Ideas backlog (not required)

- `simctl status_bar override` for clean screenshots; `simctl io screenshot` and `recordVideo`; `simctl ui appearance`; `simctl location`; `simctl privacy grant`.
- Physical devices through `devicectl`.
- Create and delete simulators; delete unavailable runtimes.
- Partial staging (hunks) and conflict resolution.
- A theme switch (dark) once the panel appearance can follow the system without recolouring the menu bar label.
- Keyboard navigation in every list (arrows, Return, Delete with confirm).
- Notifications when a build finishes while the panel is closed.
- A shortcut recorder for the global hotkey.
