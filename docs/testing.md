# Testing

This page explains how DevHub is tested: the commands, the test helpers, the integration suites, the check of the screen and the test repository for the pull request features.

Two other files hold the rules. This page does not repeat them:

- `.claude/rules/testing.md`: the short rules (shape, inputs, what is forbidden).
- `.github/skills/testing/SKILL.md`: the full guide with examples, and a table "Add a test for…".

All paths below start at `Packages/DevHubKit/` unless they start with `Scripts/` or `docs/`.

## 1. Run the tests

| Command | What it runs |
|---|---|
| `Scripts/test.sh` | every test of the package |
| `Scripts/test.sh --skip integration` | every test except the suites whose name ends in `IntegrationTests` |
| `Scripts/test.sh --filter CleanInstallPolicyTests` | one suite |
| `Scripts/test.sh --filter DevHubDomainTests` | one test target |
| `Scripts/test.sh --filter "GitStoreTests/push"` | the tests whose name matches |
| `swift test --package-path Packages/DevHubKit --filter X` | the same tests with the full output |

How `Scripts/test.sh` works:

1. It runs `swift test -q` on `Packages/DevHubKit`.
2. It changes `--skip integration` to `--skip IntegrationTests`. `swift test` cannot skip a tag, so it skips by the suite name.
3. Every other argument goes to `swift test` as it is.
4. It prints only the failure lines (`✘`, `recorded an issue`, `error:`) and the last `Test run with … passed` line. The exit code of `swift test` is kept.

A good run prints one line: `Test run with <N> tests in <M> suites passed`. On 2026-10-18 the package had 1,807 tests in 328 suites.

### When the results look wrong

After a change to an enum in a lower module (for example a new `Tint` case), remove `Packages/DevHubKit/.build` before `Scripts/test.sh`. The incremental test build once kept old object files, and the tests read wrong enum values (STATUS decision 16).

## 2. Test targets

| Target | Tests | Count (2026-10-18) |
|---|---|---|
| `Tests/DevHubDomainTests` | policies, values, models, errors, use cases over spies | about 440 |
| `Tests/DevHubDataTests` | parsers with fixtures, file code over temporary folders, mocks, integration suites | about 390 |
| `Tests/DevHubUITests` | formatters, `TagModel`, `Tint`, `Theme` | about 30 |
| `Tests/DevHubPresentationTests` | shared objects, mappers, stores over spies | about 940 |

The Domain and Data test targets are nonisolated. The UI and Presentation test targets run on the main actor, like their modules.

## 3. Conventions in short

- Swift Testing only: `@Suite struct <Type>Tests`, `@Test func <sentence>()`, `#expect`, `#require`.
- One suite per type, in `<Type>Tests.swift`. The folders mirror `Sources/<Module>/`.
- `@testable import` for the module under test.
- Arrange, act, assert, with one empty line between them.
- `Scripts/check-layers.sh` checks the test files too: one type per file, the file name is the type name.

The details are in the rule file and in the skill.

## 4. Spies and `Ports.spies()`

`DevHubTestSupport` has one spy per port. `Ports.spies()` builds a full `Ports` value from a new `PortSpies`:

```swift
let (ports, spies) = Ports.spies()
spies.launcher.inspectResult = .notInstalled

let useCases = UseCases(ports: ports)
```

Every spy follows the same shape:

1. `calls` is the list of calls in order. `Call` is a `Hashable` enum with one case per method of the port.
2. `<method>Result` is the scripted answer. `<method>Error` makes the method throw.
3. The defaults are empty successes.
4. An `NSLock` protects every stored property, so a spy is `Sendable`.

### The spies

| `PortSpies` field | Spy | Port |
|---|---|---|
| `usage` | `SpyClaudeUsageRepository` | `ClaudeUsageRepository` |
| `copilotUsage` | `SpyCopilotUsageRepository` | `CopilotUsageRepository` |
| `simulators` | `SpySimulatorRepository` | `SimulatorRepository` |
| `build` | `SpyBuildRepository` | `BuildRepository` |
| `worktrees` | `SpyWorktreeRepository` | `WorktreeRepository` |
| `launcher` | `SpyAppLaunchRepository` | `AppLaunchRepository` |
| `git` | `SpyGitRepository` | `GitRepository` |
| `changes` | `SpyGitChangesRepository` | `GitChangesRepository` |
| `logs` | `SpyAppLogRepository` | `AppLogRepository` |
| `mockServer` | `SpyMockServerRepository` | `MockServerRepository`; `emit(_:udid:)` calls the saved `onExchange` |
| `mockSets` | `SpyMockSetRepository` | `MockSetRepository`; `savedSets` |
| `messaging` | `SpySimulatorMessagingRepository` | `SimulatorMessagingRepository` |
| `codeHost` | `SpyCodeHostRepository` | `CodeHostRepository` |
| `aiSessions` | `SpyAISessionRepository` | `AISessionRepository` |
| `derivedData` | `SpyDerivedDataRepository` | `DerivedDataRepository` |
| `opener` | `SpyWorkspaceOpener` | `WorkspaceOpening` |
| `attacher` | `SpyXcodeAttacher` | `XcodeAttaching` |
| `projectDetector` | `SpyProjectDetector` | `ProjectDetecting` |
| `reviewPrompts` | `SpyReviewPromptRepository` | `ReviewPromptRepository` |
| `config` | `SpyConfigRepository` | `ConfigRepository` |
| `scripts` | `SpyScriptRunner` | `ScriptRunning` |
| `tools` | `SpyToolLocator` | `ToolLocating` |
| `notifications` | `SpyUserNotificationRepository` | `UserNotificationRepository` |

### Other helpers in `DevHubTestSupport`

| Helper | Use |
|---|---|
| `SpyCommandRecorder` | records the `CommandEvent`s of a real `ShellRunner` (`events`) |
| `CallbackRecorder<Value>` | a thread-safe list for values from a `@Sendable` callback |
| `TestError` | `.scripted("…")` for a spy error, `.timedOut` from `waitUntil` |
| `CodeHost.gitHubSample`, `CodeHost.gitLabSample` | code host values for `github.com/example/app` and a sample GitLab host |
| `GitSettings.withBootstrap` | git settings with a worktree bootstrap script |
| `TicketSettings.linking(_:)` | ticket settings with a link template |
| `TemporaryDirectory` | section 7 |
| `waitUntil` | section 8 |

### A new port needs a spy

1. Write `Sources/DevHubTestSupport/Spy<Port>.swift`. Copy the shape of `SpyGitRepository.swift`.
2. Add a field to `PortSpies.swift` and an argument to `Ports+Spies.swift`.
3. `PortSpiesTests` (`DevHubDomainTests/Support/`) checks that `UseCases` builds over the spies.

## 5. Store tests and `StoreHarness`

`Tests/DevHubPresentationTests/Stores/Support/StoreHarness.swift` builds the same object graph as `PresentationAssembly`, but over spies. It has `ports`, `spies`, `useCases`, an `InMemoryKeyValueStore`, `AppEvents`, `ActivityLog`, `ProjectSession` and one `lazy var` per store.

| Member | Use |
|---|---|
| `StoreHarness()` | one project (`ProjectSample.app`) and an empty store |
| `StoreHarness(projects:)`, `StoreHarness(store:)` | other projects, or a prepared key-value store to test saved values |
| `postedLabels`, `postCount(_:)`, `clearPosted()` | the events that the stores posted, as text labels (`AppEvent+Matching.swift`) |
| `activityTitles`, `lastActivity` | the activity log |
| `copied` | the text that the `Toaster` copied |
| `settle()` | yields 100 times; use it only to show that something did **not** happen |

Two more helpers in the same folder:

- `ObservationProbe` tells whether a read of a store property gets an Observation change. Use it to check that a store does not publish a change when the value is the same.
- `AppEvent+Matching.swift` gives every event a label for the checks above.

A store subscribes to events in its `init`. Touch the lazy store first (`_ = harness.identity`), then post the event.

## 6. Fixtures and samples

Fixtures are `enum`s with `static let` values in a `Fixtures/` folder of each target:

| Target | Fixtures |
|---|---|
| `DevHubDataTests` | `GhFixture`, `GlabFixture`, `GlabGraphQLFixture`, `GitStatusFixture`, `WorktreePorcelainFixture`, `SimctlListFixture`, `HTTPRequestFixture`, `ClaudeTranscriptFixture`, `ClaudeUsageFixture` |
| `DevHubDomainTests` | `BuildRequestFixture`, `ConfigFixture`, `GitBranchFixture`, `IdentityLaunchFixture`, `MockRuleFixture`, `NetworkRequestFixture`, `PullRequestSummaryFixture`, `SimulatorFixture`, `WorktreeFixture` |
| `DevHubPresentationTests` | mapper inputs, for example `IdentityContextFixture`, `PullRequestFixture`, `GitSnapshotFixture`, `CommandLogEntryFixture` |

Store tests use samples in `Tests/DevHubPresentationTests/Stores/Samples/`, for example `ProjectSample`, `LaunchConfigSample`, `MockSetSample`, `NetworkRequestSample`. Samples have their own names so that they do not collide with mapper fixtures.

Fixture rules that the other files do not state:

1. Recorded command output (`gh`, `glab`, `simctl`, `git`) is anonymised before it goes into a fixture. Use the sample vocabulary of `.claude/rules/anonymity.md`: `github.com/example/app`, `ABC-123`, `alex`, `sam`.
2. A fixture with a secret uses a fake value. The test checks that the value is absent from every output field.
3. `Scripts/check-anonymous.sh` reads the test files too. A real host or bundle ID in a fixture fails the build.

## 7. Files and other test doubles

| Helper | Where | Use |
|---|---|---|
| `TemporaryDirectory` | `DevHubTestSupport` | a new folder in `init`, removed in `deinit`; `write(_:to:)` creates the parent folders; `path(_:)` gives a path inside |
| `TemporaryGitRepository` | `DevHubDataTests/Support/` | `git init -b main`, two commits, branches `feature` and `merged-branch`, a linked worktree `linked`; runs real `git` |
| `SimulatorContainerTree` | `DevHubDataTests/Support/` | a fake simulator data container for `ContainerLocator` |
| `StubURLProtocol` | `DevHubDataTests/Support/` | a `URLSession` that answers from a closure; the mock server forwards to it instead of the network |
| `RawHTTPClient` | `DevHubDataTests/Support/` | sends raw bytes to the mock server, for example a WebSocket upgrade |
| `GatedSimulatorRepository` | `DevHubDomainTests/Support/` | a simulator repository whose `boot` waits until the test releases it; for cancellation tests |
| `InMemoryKeyValueStore` | `DevHubMocks` | saved values without `UserDefaults` |

Never write into the real home folder, into a hand-made `/tmp` path or into `UserDefaults.standard`.

## 8. `waitUntil`

`try await waitUntil { condition }` checks the condition on the main actor every 5 ms. It throws `TestError.timedOut` after 10 seconds. Use it for work that a store starts in a `Task`. Never use `Task.sleep` in a test.

The default was 2 seconds. Right after a build, about 25 store tests waited longer on the busy main actor and failed. The tests passed when they ran alone (STATUS decision 14).

## 9. Integration suites

An integration suite runs a real process or a real socket. It has `.tags(.integration)` and a name that ends in `IntegrationTests`. Both are required, because `Scripts/test.sh --skip integration` skips by the name.

| Suite | Folder in `DevHubDataTests` | What it runs |
|---|---|---|
| `ShellRunnerIntegrationTests` | `Integration/` | `/bin/echo`, `sh` |
| `GitCommandRunnerIntegrationTests` | `Integration/` | `git` over `TemporaryGitRepository` |
| `ShellGitRepositoryIntegrationTests` | `Integration/` | `git` |
| `ShellGitChangesRepositoryIntegrationTests` | `Integration/` | `git` |
| `ShellWorktreeRepositoryIntegrationTests` | `Integration/` | `git worktree` |
| `MergedBranchesQueryIntegrationTests` | `Integration/` | `git` |
| `MockServerIntegrationTests` | `Integration/` | the mock server on a real local socket |
| `GhIntegrationTests` | `Integration/` | `gh` against the test repository (section 11); skipped without `DEVHUB_PLAYGROUND` |
| `GlabIntegrationTests` | `Integration/` | `glab` against a GitLab test project (section 12); skipped without `DEVHUB_GITLAB_PLAYGROUND` |
| `ConfigWatcherIntegrationTests` | `Config/` | the config file watcher over a temporary folder |
| `ShellScriptRunnerIntegrationTests` | `Config/` | a config script through `/bin/sh`: output lines, exit code, timeout |

Run them all with `Scripts/test.sh --filter IntegrationTests`.

## 10. Check the screen

Tests do not cover SwiftUI views. Before a commit that changes a view, check the screen. Without a display session, use a headless snapshot. The switches work in Debug builds only (`DevHubComposition/Debug/DebugLaunch.swift`).

```sh
Scripts/build.sh
APP=DerivedData/Build/Products/Debug/DevHub.app
SHOT=/path/in/your/scratch/folder/git.png
DEVHUB_PROJECT=/path/to/a/throwaway/repo DEVHUB_OPEN_PANEL=1 DEVHUB_TAB=git \
DEVHUB_SNAPSHOT="$SHOT" DEVHUB_SNAPSHOT_DELAY=3 "$PWD/$APP/Contents/MacOS/DevHub" &
for i in $(seq 1 40); do [ -f "$SHOT" ] && break; sleep 0.25; done
pkill -f "^$PWD/$APP/Contents/MacOS/DevHub"
```

Then open the picture.

| Switch | Effect |
|---|---|
| `DEVHUB_OPEN_PANEL=1` | opens the panel 0.5 s after start. The switches below need it |
| `DEVHUB_TAB=<id>` | selects a tab: `home`, `git`, `pullRequests`, `worktrees`, `simulators`, `logs`, `network`, `ai`, `settings`, or `tab.<id>` for a custom tab. The choice is saved |
| `DEVHUB_SNAPSHOT=<png path>` | writes a picture of the panel |
| `DEVHUB_SNAPSHOT_DELAY=<seconds>` | the wait between the open panel and the picture; default 1 |
| `DEVHUB_PALETTE=<text>` | opens the command palette with this text |
| `DEVHUB_SHOW_OUTPUT=1` | opens the Output panel (saved) |
| `DEVHUB_PROJECT=<path>` | adds and selects a project (saved) |

The switches that drive work without clicks (`DEVHUB_RUN_ACTION`, `DEVHUB_GIT_OPS`, `DEVHUB_BUILD_RUN`, `DEVHUB_MOCK`, `DEVHUB_LOG_STREAMS` and others) are listed in STATUS decision 9 and in the `build-and-run` skill.

Snapshot traps (STATUS decision 10):

1. SwiftUI does not redraw a panel that other windows cover. The picture can show an old state.
2. `cacheDisplay` does not draw some controls. A prominent button looks empty.
3. A snapshot cannot open a menu, a popover or a system dialog.

Check the result on the command line too, for example in the Output panel text or with `git log`.

Use a throwaway repository for anything that runs actions or git steps. `DEVHUB_PROJECT` and `DEVHUB_TAB` change saved preferences of the Debug build.

## 11. The test repository for pull requests

The pull request features were checked on a private test repository on GitHub. The GitHub account on this machine exists only for that repository (STATUS decision 1). Do not write the name of the account or the repository in a doc, a test, a fixture or a commit message.

### What the repository needs

1. Open pull requests. At least one of them has an open review thread.
2. One merged pull request.
3. A GitHub Actions workflow, so that pull requests have check runs.
4. `gh` logged in with the scopes `repo` and `workflow`.

### Automatic check

`GhIntegrationTests` reads the repository through `gh`. It runs only when `DEVHUB_PLAYGROUND` is set:

```sh
DEVHUB_PLAYGROUND=<owner>/<repo> Scripts/test.sh --filter GhIntegrationTests
```

Without the variable the suite is skipped, so `Scripts/test.sh` stays green on any machine. The suite only reads. It never approves, merges or writes.

### Manual check

Add a local clone of the test repository as a project (`DEVHUB_PROJECT=<path>`) and open the Pull Requests tab. In M4 these flows were checked by hand:

1. the list in four scopes;
2. details with a thread, and the changed files;
3. draft and ready;
4. update branch;
5. merge with branch removal;
6. create with labels;
7. reply and resolve;
8. re-run and cancel a check run.

Flows that change the repository (merge, create, resolve) change it for real. Create a new branch and pull request for each run.

### Limits of the test repository

- A private repository on a free plan has no branch protection and no auto-merge. The auto-merge action stays hidden there (`autoMergeAllowed` is false).
- The GitLab flows need a GitLab host of the owner. No GitLab test repository exists.


## 12. The test project for merge requests

`GlabIntegrationTests` runs against a private GitLab test project. It runs only when `DEVHUB_GITLAB_PLAYGROUND` is set:

```sh
DEVHUB_GITLAB_PLAYGROUND=<host>/<owner>/<project> Scripts/test.sh --filter GlabIntegrationTests
```

The host and the project come only from the variable. They never go into the repository.

This suite writes. Each run:

1. creates a branch `devhub-test-<random>` with one file through the GitLab API;
2. creates a draft merge request from it;
3. sets it to ready, to draft and to ready again;
4. starts a thread, replies to it and resolves it;
5. merges it with squash and branch removal.

A second test reads the labels and the diff of a merged request.

Not covered: approve and unapprove (GitLab may not allow approving your own request), auto-merge and pipelines (the test project has no CI).

## 12. Before a commit

1. `Scripts/build.sh` prints `layers: ok`, `anonymous: ok` and the app path.
2. `Scripts/test.sh` prints one `Test run with … passed` line.
3. `Scripts/smoke.sh` prints `alive`.
4. New logic has a test. A missing test counts as a failure.
5. A changed view was seen on the screen or in a snapshot.

## 13. CI on GitHub Actions

`.github/workflows/ci.yml` runs on a GitHub-hosted `macos-26` runner for each push of `main` and each pull request. The steps are the same as before a local commit, in this order:

1. `Scripts/check-layers.sh`.
2. `Scripts/check-anonymous.sh`. The denylist lives outside the repository, so CI checks only the built-in patterns (bundle IDs, plist suites, hosts).
3. `SKIP_LAYER_CHECK=1 Scripts/build.sh Debug`.
4. `Scripts/smoke.sh`.
5. `Scripts/test.sh`, every test, the integration suites included. `GhIntegrationTests` and `GlabIntegrationTests` skip themselves without their environment variables.

A run takes about ten minutes, most of it the first build. The Actions tab of the repository shows the state of the last run on `main`; there is no badge, because the repository slug may not appear in the files. A red run on `main` is fixed before any other push.
