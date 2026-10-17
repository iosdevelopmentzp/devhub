# DevHub

Personal macOS menu bar panel for daily development work across many repositories: git, worktrees, simulators, builds, logs, AI sessions, quick actions and scripts. Generic core; project knowledge lives in `.devhub/` config files.

Read first, in this order: this file, `docs/STATUS.md` (where the project stands), `docs/SPEC.md` (what to build and how), `docs/extensions.md` (the config schema). Skills under `.github/skills/` explain how to do common tasks; load the matching one before the task.

## Project

- Xcode project `DevHub.xcodeproj`, one target `DevHub`. Swift 5 language mode, default actor isolation `MainActor`, approachable concurrency on. No tests: no unit tests, no UI tests, no test target. The check is a clean build plus a run.
- No App Sandbox. Ad-hoc signing ("Sign to Run Locally"). `INFOPLIST_KEY_LSUIElement = YES`: no Dock icon by default. Keep it this way: a sandbox would block `git`, `xcrun` and `xcodebuild`.
- Xcode synchronized folder: a file added under `DevHub/` joins the target by itself. Edit `project.pbxproj` only for build settings, never for file lists.
- No third-party packages. Foundation, AppKit, SwiftUI, Observation, Carbon (hot key), ServiceManagement only.

## Build and run

| Command | What it does |
|---|---|
| `Scripts/build.sh [Debug\|Release]` | `xcodebuild -quiet` into `DerivedData/`, prints the `.app` path. Any other output is an error or a warning: fix it |
| `Scripts/run.sh` | Debug build, quits a running DevHub, opens the new build |
| `Scripts/install.sh` | Release build into `/Applications/DevHub.app` |
| `Scripts/smoke.sh` | Starts the Debug build headless for 3 s and prints `alive` or `dead` |

Run `Scripts/build.sh` after every change. Warnings count as failures. Run `Scripts/run.sh` and look at the screen before every commit that changes a view.

## Layout

```
DevHub/App          @main, AppDelegate, AppDependencies (composition root), DebugLaunch (+Logs), DebugGitOps, MenuBarUsage
DevHub/Core         models, config schema and merge, pure parsers, LogRedactor   (Foundation only)
DevHub/Services     ShellRunner, CommandRecorder, CommandLog, Providers bundle, Git/ (git, worktrees, pull requests) Xcode/ Simulators/ Logs/ AI/ (sessions and usage) Config/ Workspace/ (WorkspaceActions, Clipboard, GlobalHotKey)
DevHub/Shared       ProjectSession (project list, selection, checkout), ConfigStore, GitExecutor (the one git write path), ActionCatalog, ActionRunner, ProjectActions, Navigator, ActivityLog, Toaster, OutputPanelState, SettingsStore, AppPreferences, AppEvents, WindowLayout
DevHub/Features/X   XStore.swift plus one file per view (Home, Git, Worktrees, Simulators, Logs, AI, Usage, Actions, Settings)
DevHub/Shell        AppWindows, FeatureRegistry, RootView, HeaderView, FeatureTabBar, FooterView, ProjectMenu, SearchFilterBar, Output/, drag and resize
DevHub/UI           Theme, Components/ (one file per block), FlowLayout, Hint/, CopyOnClick, ToastOverlay, WindowAppearance
Scripts             build, run, install, launcher, ai/ (hook scripts)
docs                SPEC.md, STATUS.md, extensions.md, examples/
```

Dependency direction, strict: `App → Shell → Features → Shared → Services → Core`. `Core` imports Foundation only. Only `Services/Workspace` may import AppKit, except window plumbing in `Shell` (panel, status item, drag, resize) and `UI` (appearance, hint monitor). Views never run commands; stores never import SwiftUI.

## Architecture rules

- One `@MainActor @Observable final class <Name>Store` per feature. It owns the feature state and every mutation. Views read it from the environment. Bindings: `@Bindable var store = store` as the first line of `body`.
- A store gets its provider and the lower stores it reads through `init`. Stores depend one way: `Shared ← Worktrees, Simulators, Usage, Sessions ← Git ← Build`. A lower store never knows a higher one.
- Stores tell each other "something changed" through `AppEvents` (`projectChanged`, `branchesChanged`, `worktreesChanged`, `simulatorsChanged`, `configChanged`, `commandFailed`). Add a case only when a second store needs to react.
- Actions that cross features are wired in views: `navigator.show("simulators")` then `build.run(branch:)`.
- Real data enters a store only through a provider protocol from the `Providers` bundle (`.live` and `.mock`). Long work returns `AsyncThrowingStream`; cancelling the consumer terminates the process.
- Every external command goes through `ShellRunner`, so it lands in `CommandLog` and the Output panel. Never `Process` directly. Never on the main actor.
- Every failure is visible: `ActivityLog.log(…, outcome: .failure)`, the Output panel opens. No silent `catch`.
- Secrets: tokens are read for one request and dropped; `security` output is never recorded; log lines pass through `LogRedactor` before they are stored; nothing of that is written to disk.
- Nothing project-specific in Swift: no project name, path, bundle ID or branch name. Such facts come from `.devhub/` config (`docs/extensions.md`).
- Persistence in `UserDefaults` through `AppPreferences` with named keys. The app never writes into `.devhub/` except "Create example".
- One view per file. A file over ~300 lines gets split into a row, a toolbar or a panel.

## Swift conventions

- No comments. Names and small functions carry the meaning. `// MARK: -` for file sections only.
- `guard` for early exit. `== false` instead of `!`.
- A `[weak self]` closure starts with `guard let self else { return }` on its own line; no `self.` after that.
- Member order: environment and dependencies, `let` inputs, `@State`, `body`, private computed properties, private functions.
- Default parameter values only for cosmetic view inputs (`tint`, `size`) and `@ViewBuilder` closures.
- One concern per `extension`. Multi-line calls: first argument on a new line, closing `)` on its own line.
- Types that must run off the main actor are `actor` or `nonisolated`.

## UI conventions

Reference with code in the `ui-components` skill.

- Panel 720 × 820 by default, resizable, minimum 640 × 560. Layouts stretch; no fixed widths for rows or screens. Horizontal padding 14, row vertical padding 7 to 8, dividers inset 56.
- Rows reveal actions on hover with `opacity`, never with a layout change. `IconButton` for icon actions, `OverflowMenu` for the rest, the same actions in `.contextMenu`.
- Every icon without text has a hover hint (`IconButton(help:)` or `.hint(_:)`), never `.help`. Buttons and tags are never cut: `.fixedSize()`, `ActionBar` for long button rows, `FlowLayout` for tag rows, `.hintWhenTruncated(_:)` for cut text.
- Destructive actions confirm inline inside the row. No alerts, no sheets.
- Light scheme forced on the panel window (`WindowAppearance(name: .aqua)` plus `.colorScheme(.light)`). Never set `NSApp.appearance`.
- Colours only through `Theme` tokens and semantic tints (green clean, orange dirty, red failure or destructive, blue current or target, purple merged or scripts, indigo project). No hex values outside `Theme`.
- Monospaced font for paths, file names, hashes and commands. Click-to-copy for paths, branches, hashes and IDs through `.copyOnClick`.
- Every list filters with `session.matchesSearch(...)` and shows `ContentUnavailableView.search` when empty. Every picker with many items is a `SearchablePicker`.
- Every screen file ends with `#Preview { XView().previewEnvironment() }`.

## Plain English

Documentation, UI text, hints, commit messages and the changelog use short sentences and common words. No idioms, no metaphors. A technical term stays exact.

## Memory between sessions

- `CHANGELOG.md`: what changed, newest first. Every session that changes code adds lines under `[Unreleased]` before it ends. The stop hook blocks a session that changed `DevHub/`, `Scripts/` or `.github/` without touching the changelog.
- `docs/STATUS.md`: stage, what is real per screen, decisions that must not be undone, next steps, known gaps. Update at the end of every milestone.
- `docs/extensions.md`: must match the config decoder.
- Skills under `.github/skills/` (`.claude/skills` is a symlink to it): update the skill when the thing it describes changes.
- The remote is always a working app. Commit only when `Scripts/build.sh` is clean and the app launches (smoke check in the `build-and-run` skill). Commit and push after every finished feature, not only after a milestone. A half-done feature is not reachable from the UI. Never force-push. `README.md` tells how to clone and run.

## Skills

- `add-feature`: add a screen or tab end to end.
- `ui-components`: shared blocks, row pattern, spacing, colours.
- `providers-and-shell`: provider protocols, `ShellRunner`, streaming, command classification.
- `xcode-toolchain`: `xcodebuild`, `simctl`, DerivedData, product lookup, signing trap, log streams, Xcode attach.
- `panel-window`: status item, panel, position, appearance, hints, hot key.
- `extensions`: add an action, a script, a launch profile or a custom tab through `.devhub/`, and extend the schema.
- `build-and-run`: build scripts, smoke check, debug launch switches, common failures.
- `update-docs`: end-of-session pass over changelog, status, this file and the skills.
