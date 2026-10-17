# DevHub

Personal macOS menu bar panel for daily development work across many repositories: git, worktrees, pull requests, simulators, builds, logs, network mocks, AI sessions, quick actions and scripts. The core is generic. Project knowledge lives in `.devhub/` config files.

Read first, in this order: this file, `docs/STATUS.md` (where the project stands), `docs/adr/001-port-from-main-devhub.md` (the plan of the current rewrite and its step log), `docs/adr/002-config-system.md` (how the config system sits in the modules), `docs/ARCHITECTURE.md` (the module contract), `docs/extensions.md` (the config schema). Skills under `.github/skills/` explain how to do common tasks; load the matching one before the task.

## Project

- Xcode project `DevHub.xcodeproj`, one app target `DevHub`, macOS 26.4+, Swift 6 language mode. The target holds only `DevHub/DevHubApp.swift` and `Assets.xcassets` and links the product `DevHubComposition`.
- Local package `Packages/DevHubKit` (tools 6.2, Swift 6) with the modules `DevHubDomain`, `DevHubData`, `DevHubMocks`, `DevHubUI`, `DevHubPresentation`, `DevHubComposition`, `DevHubTestSupport` and four test targets. `project.pbxproj` holds the package reference.
- No App Sandbox. Ad-hoc signing ("Sign to Run Locally"). `INFOPLIST_KEY_LSUIElement = YES`: no Dock icon by default. Keep it this way: a sandbox would block `git`, `xcrun` and `xcodebuild`.
- `DevHub/` is an Xcode synchronized folder. Edit `project.pbxproj` only for build settings, never for file lists. New code goes into the package.
- `legacy/` holds the Swift sources of the first generic app. It is not built. It is the port source for the config system, Copilot support and debug switches until milestone M7 deletes it.
- No third-party packages.
- The repository has no remote. Never push it anywhere. The GitHub account on this machine is only for a playground repository that tests the pull request features.

## Build and test

| Command | What it does |
|---|---|
| `Scripts/build.sh [Debug\|Release]` | Runs `Scripts/check-layers.sh` and `Scripts/check-anonymous.sh`, then `xcodebuild -quiet` into `DerivedData/`, prints the `.app` path. `SKIP_LAYER_CHECK=1` skips the layer check |
| `Scripts/test.sh [args]` | `swift test -q` on the package, one summary line, exit code forwarded. `--skip integration` skips the process suites, `--filter <Suite>` runs one suite |
| `Scripts/smoke.sh` | Starts the Debug build headless for 3 s and prints `alive` or `dead` |
| `Scripts/run.sh` | Debug build, quits a running copy of this build, opens the new one |
| `Scripts/install.sh` | Release build into `/Applications/DevHub.app` |
| `Scripts/check-anonymous.sh` | Fails on a name of the owner's projects (from `~/.devhub/anonymity-denylist.txt`, outside the repository), a bundle ID, plist suite or host that is not a sample value, in any file or in the last commit message |

Every change: `Scripts/build.sh` prints `layers: ok`, `anonymous: ok` and the app path; anything else is a failure. `Scripts/test.sh` prints one `Test run with … passed` line. A missing test for new logic counts as a failure. Before a commit that changes a view, look at the screen: `Scripts/run.sh`, or a headless snapshot (`DEVHUB_OPEN_PANEL=1 DEVHUB_TAB=git DEVHUB_SNAPSHOT=<path>.png`, see the `build-and-run` skill).

The scripts stop only the build of this repository (by its path). Another app called DevHub on the same machine keeps running.

## Layout

Modules, one direction: `Composition → Presentation → Domain ← Data`; Presentation also uses UI and, for previews only, Mocks. The compiler enforces the direction. The full contract is in `docs/ARCHITECTURE.md`, the short rules in `.claude/rules/`, the extra checks in `Scripts/check-layers.sh`.

| Path | Purpose |
|---|---|
| `DevHub/` | `DevHubApp.swift` (`@main`, keeps `AppContainer.live()` alive), `Assets.xcassets` |
| `Packages/DevHubKit/Sources/DevHubDomain` | models, values, ports, policies, use cases, errors, `Ports`, `UseCases` |
| `Packages/DevHubKit/Sources/DevHubData` | live repositories, `ShellRunner`, parsers, `Ports.live(shell:)`; AppKit only in `Workspace/`, Network.framework only in `Network/MockServer/` |
| `Packages/DevHubKit/Sources/DevHubMocks` | `Mock*Repository`, `MockData`, `InMemoryKeyValueStore`, `Ports.mock()` |
| `Packages/DevHubKit/Sources/DevHubUI` | shared SwiftUI blocks, `Theme`, `Tint`, formatters, hints |
| `Packages/DevHubKit/Sources/DevHubPresentation` | stores, row models and mappers, views, events, `PresentationAssembly`, `AppWindows` |
| `Packages/DevHubKit/Sources/DevHubComposition` | `AppContainer`, `Debug/DebugLaunch` (headless switches, Debug builds only) |
| `Packages/DevHubKit/Sources/DevHubTestSupport` | one `Spy<Port>` per port, `Ports.spies()`, test helpers, sample values |
| `Packages/DevHubKit/Tests` | `DevHubDomainTests`, `DevHubDataTests`, `DevHubUITests`, `DevHubPresentationTests` |
| `Scripts/` | build, test, layer and anonymity checks, run, install, smoke, launcher, `ai/` hooks |
| `docs/` | `ARCHITECTURE.md`, `STATUS.md`, `SPEC.md`, `extensions.md`, `adr/`, `examples/` |
| `legacy/` | the first generic app, port source only, not built |

## Conventions

### Swift

- No comments. Names and small functions carry the meaning. `// MARK: -` for file sections only.
- Domain, Data, Mocks and TestSupport are nonisolated by module default: never write `nonisolated` on a type there. UI, Presentation and Composition are MainActor by default. Never fix an isolation error with `MainActor.assumeIsolated`.
- `package` before every declaration another module uses, including `package init`, `package var body` and `package static let`. `public` only in `DevHubComposition`.
- `guard` for early exit. `== false` instead of `!`.
- A `[weak self]` closure starts with `guard let self else { return }` on its own line; no `self.` after that.
- Member order: environment and dependencies, `let` inputs, `@State`, `body`, private computed properties, private functions.
- Default parameter values only for cosmetic view inputs (`tint`, `size`), `@ViewBuilder` closures, and a `package init` that copies a memberwise init.
- One top-level type per file, the file name is the type name; an extension of another type lives in `<Type>+<Concern>.swift`.
- Multi-line calls: first argument on a new line, closing `)` on its own line.

### Architecture

- One `@Observable final class <Feature>Store` per feature. It owns the feature state and every mutation. It never holds another feature's store: reads go through a lookup protocol in `Shared/`, changes through a use case, and the owner refreshes on an `AppEvent`.
- Real data enters only through a Domain port. Every process goes through `ShellRunner`, so it lands in the command log and the Output panel. Never `Process` elsewhere, never on the main actor.
- Every failure is visible: `ActivityLog.log(…, outcome: .failure)`. No silent `catch`.
- Secrets: a token is read for one request and dropped; `security` output is never recorded; log lines pass through `LogRedactor`.
- Nothing project-specific in Swift: no project name, path, bundle ID, host or branch name. Such facts come from `.devhub/` config (`docs/extensions.md`). Sample data uses one vocabulary (`Example App`, `com.example.app`, `ABC-123`, `github.com/example/app`, `example://`), listed in `.claude/rules/anonymity.md`.

### Tests

Full guide: the `testing` skill.

- Swift Testing. `@Suite struct <Type>Tests`, one per type, in `<Type>Tests.swift`; folders mirror `Sources/`; `@testable import <Module>`.
- Spies from `DevHubTestSupport` (`Ports.spies()`), fixtures in `Fixtures/<Thing>Fixture`, store samples in `Stores/Samples/<Thing>Sample`, files only through `TemporaryDirectory`.
- No `Task.sleep`; `waitUntil { … }` for fire-and-forget work. Never assert on locale or clock text.
- Integration suites: `.tags(.integration)` and a name ending in `IntegrationTests`.

### UI

Full reference with code: the `ui-components` skill.

- Panel 720 × 820 by default, resizable, minimum 640 × 560. Layouts stretch; no fixed widths for rows or screens. Horizontal padding 14, row vertical padding 7 to 8, dividers inset 56.
- Rows reveal actions on hover without a layout change. `IconButton` for icon actions, `OverflowMenu` for the rest, the same actions in `.contextMenu`.
- Every icon without text has a hover hint (`IconButton(help:)` or `.hint(_:)`), never `.help`. Buttons and tags are never cut.
- Destructive actions confirm inline inside the row (`InlineConfirmation`). No alerts, no sheets.
- Light scheme forced on the panel window (`WindowAppearance(name: .aqua)` plus `.colorScheme(.light)`). Never set `NSApp.appearance`.
- Colours only through `Theme` tokens and `Tint` in row models. No hex values outside `Theme`.
- Monospaced font for paths, file names, hashes and commands.
- Every screen ends with `#Preview { XView().previewEnvironment() }`; every row with `#Preview { XRow(model: .preview, …) }`.

## Plain English

Documentation, UI text, hints, commit messages and the changelog use short sentences and common words. No idioms, no metaphors. A technical term stays exact.

## Memory between sessions

- `CHANGELOG.md`: what changed, newest first. Every session that changes code adds lines under `[Unreleased]`. The stop hook blocks a session that changed `DevHub/`, `Packages/`, `Scripts/`, `.github/` or `.claude/rules/` without touching the changelog.
- `docs/STATUS.md`: stage, what is real per screen, decisions that must not be undone, next steps, known gaps.
- `docs/adr/001-port-from-main-devhub.md`: one step log row per commit (hash and what it did). A commit cannot hold its own hash, so its row lands in the next commit.
- Commit after every finished step, only when build, tests, the anonymity check and the smoke check are green. Conventional commits (`feat:`, `fix:`, `docs:`, `refactor:`, `chore:`) with a plain English body. A half-done feature is not reachable from the UI.

## Skills

- `add-feature`: add a screen or tab end to end through the modules, with tests.
- `add-use-case`: policy or use case, lookup protocols, events, use case tests.
- `data-layer`: repositories, `ShellRunner`, runners, parsers, persistence, `Ports.live`, mocks.
- `testing`: Swift Testing conventions, spies, store harness, fixtures, integration suites.
- `ui-components`: DevHubUI blocks, row model and mapper pattern, formatters, `Tint`, spacing.
- `xcode-toolchain`: `xcodebuild`, `simctl`, DerivedData, product lookup, signing trap, log streams, Xcode attach.
- `panel-window`: status item, panel, pinned window, position, appearance, hints, hot key.
- `extensions`: the `.devhub/` config (actions, scripts, launch profiles, custom tabs) and how to extend the schema.
- `build-and-run`: build scripts, smoke check, debug launch switches, common failures.
- `update-docs`: end-of-session pass over changelog, status, ADR step log, this file and the skills.

Skills not yet rewritten for the package (`add-feature`, `providers-and-shell`, `build-and-run`, `panel-window`, `ui-components`, `xcode-toolchain`, `update-docs`) still describe the first generic app in places. `docs/STATUS.md` lists what is stale; the milestone that touches the area updates the skill.
