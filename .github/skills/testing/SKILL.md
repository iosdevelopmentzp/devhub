---
name: testing
description: "How DevHub is tested: Swift Testing conventions in Packages/DevHubKit/Tests, the DevHubTestSupport spies (Spy<Port>, Ports.spies(), PortSpies), StoreHarness for store tests, fixtures and samples, TemporaryDirectory, waitUntil, integration suites over real git and sh, running and filtering with Scripts/test.sh, what not to test, and how to add a test for a new mapper, store, parser, policy or use case. Load before writing or changing any test, adding a port (it needs a spy), or when Scripts/test.sh fails."
---

# Testing

Short rules: `.claude/rules/testing.md`. Contract: `docs/ARCHITECTURE.md` section 8. All paths below are under
`Packages/DevHubKit/`.

## Targets

| Target | Tests | Imports |
|---|---|---|
| `Tests/DevHubDomainTests/` | policies, values, models, errors, every use case over spies | `@testable import DevHubDomain`, `DevHubTestSupport` |
| `Tests/DevHubDataTests/` | encoders, parsers with fixtures, file-bound code over temporary folders, mocks, `Integration/` | `@testable import DevHubData`, `DevHubMocks`, `DevHubTestSupport` |
| `Tests/DevHubUITests/` | formatters, `TagModel`, `Tint`, `Theme` | `@testable import DevHubUI` |
| `Tests/DevHubPresentationTests/` | `Shared/` objects, `Mappers/` tables, `Stores/` over spies | `@testable import DevHubPresentation`, `DevHubMocks`, `DevHubTestSupport` |

Domain and Data test targets are nonisolated; UI and Presentation test targets are MainActor, like their modules.
On 2026-10-18 the package had 1,807 tests in 328 suites. A full run takes a few seconds after the build.

## Running

```sh
Scripts/test.sh                                # everything, one summary line, exit code forwarded
Scripts/test.sh --skip integration             # without the *IntegrationTests suites
Scripts/test.sh --filter WorktreesStoreTests   # one suite
Scripts/test.sh --filter DevHubDomainTests     # one target
Scripts/test.sh --filter "GitStoreTests/push"  # tests whose name matches
swift test --package-path Packages/DevHubKit --filter X   # the full output, when the summary is not enough
```

`test.sh` keeps only failure lines (`✘`, `recorded an issue`, `error:`) and the final `Test run with …` line.

`swift test` runs the suites in parallel by default and queues every test at once. A main-actor test hops to the
main actor from its task, so the main queue holds every main-actor test of the run from the first millisecond, and
each later hop to the main actor (a `waitUntil` check, a store `Task`, the wake-up of a `Task.sleep`) waits behind
that queue: about 3 s on 14 cores, about 10 s on the 3-core CI runner, which is the `waitUntil` timeout. CI runs
`Scripts/test.sh --no-parallel`: one test after another, no queue, about 17 s instead of 4 s on a laptop. Use
`--no-parallel` locally when a store test times out in a full run but passes alone.

## Conventions

- `import Testing`, `@Suite struct <Type>Tests`, `@Test func <sentence>()`, `#expect`, `#require`.
- One suite per type under test, file `<Type>Tests.swift`, folders mirror `Sources/<Module>/`. The lint applies the
  file rule to Tests: the file name must match the declared type, so an extension `String+Shell` is tested by
  `StringShellTests` in `StringShellTests.swift`.
- Arrange, act, assert, separated by one empty line. One behaviour per test.
- No comments, `== false`, `guard let self` on its own line. A `private` helper under ~30 lines may stay in the
  test file; a helper used by two files goes to the target's `Support/` folder; a helper for two targets goes to
  `DevHubTestSupport`.
- `// MARK: Name` groups tests inside a long suite (`// MARK: Refresh`).

## Spies (`Sources/DevHubTestSupport/`)

One `Spy<Port>` per port: `SpyGitRepository`, `SpyGitChangesRepository`, `SpyWorktreeRepository`,
`SpyCodeHostRepository`, `SpySimulatorRepository`, `SpyDeviceRepository`, `SpySimulatorMessagingRepository`, `SpyBuildRepository`,
`SpyAppLaunchRepository`, `SpyDerivedDataRepository`, `SpyAppLogRepository`, `SpyMockServerRepository` (`emit(_:udid:)` calls the saved `onExchange`), `SpyMockSetRepository` (`savedSets`), `SpyAISessionRepository`, `SpyCopilotUsageRepository`,
`SpyClaudeUsageRepository`, `SpyWorkspaceOpener`, `SpyXcodeAttacher`, `SpyProjectDetector`,
`SpyReviewPromptRepository`, `SpyConfigRepository`, `SpyScriptRunner`, `SpyToolLocator`,
`SpyUserNotificationRepository`, `SpyCrashReportRepository` (`emitChange()`), `SpyAppDataRepository` (`readResult`, `actionError`), `SpyAITextRepository` (`generateResult`; `SpyGitChangesRepository.patchResult` gives the diff), `SpyDiskCleanupRepository` (`itemsResult`, `sizes`, `cleanError`), plus `SpyCommandRecorder` (`events`) and `CallbackRecorder<Value>` (a thread-safe list for `@Sendable` callbacks).

- `calls: [Call]` records every call in order. `Call` is a `Hashable` enum with one case per port method.
- Scripted answers: `<method>Result` (`Result<Value, any Error>` or a plain value) and `<method>Error`
  (`(any Error)?`). Defaults are empty successes.
- `final class … : <Port>, @unchecked Sendable` with an `NSLock` around every stored property.
- `let (ports, spies) = Ports.spies()` gives a full `Ports` built from a fresh `PortSpies`.

```swift
let (ports, spies) = Ports.spies()
spies.worktrees.listResult = .success([WorktreeFixture.main])
spies.git.performError = TestError.scripted("offline")

let summary = await UseCases(ports: ports).removeWorktree.execute(…)

#expect(spies.worktrees.calls == [.remove(WorktreeFixture.feature, projectPath: "/repo")])
```

`SpyGitRepository.performError` fails every command. To fail only one command, write a `private` fake in the test
file (see `PushRejectingGitRepository` in `GitChangesStoreTests.swift`).

### Add a spy for a new port

1. `Sources/DevHubTestSupport/Spy<Port>.swift`: copy `SpyGitRepository.swift`. One `Call` case per method, one
   locked property per scripted answer, `package` on the class, its init, `calls`, the answers and the witnesses.
2. A field in `PortSpies.swift` and one argument in `Ports+Spies.swift`.
3. `PortSpiesTests` (`DevHubDomainTests/Support/`) checks that `UseCases` builds over the spies; add a test there
   when the new spy has unusual defaults.

## Store tests (`Tests/DevHubPresentationTests/Stores/`)

`Stores/Support/StoreHarness.swift` builds the same graph as `PresentationAssembly` over spies: `ports`, `spies`,
`useCases`, `InMemoryKeyValueStore`, `AppEvents`, `ActivityLog`, `ProjectSession`, and one `lazy var` per store. A
`Toaster` writes into `copied`. It records every posted event: `postedLabels`, `postCount(_:)`, `clearPosted()`.
`activityTitles` and `lastActivity` read the activity log. `settle()` yields a hundred times; use it only to show
that something did **not** happen.

```swift
@Suite struct WorktreesStoreTests {
    private let harness = StoreHarness()

    private var store: WorktreesStore {
        harness.worktrees
    }

    @Test func refreshLoadsTheListAndTheBaseBranch() async {
        harness.spies.worktrees.listResult = .success([WorktreeSample.main, WorktreeSample.feature])

        await store.refresh()

        #expect(store.worktrees == [WorktreeSample.main, WorktreeSample.feature])
        #expect(harness.postedLabels == ["worktreesChanged"])
    }

    @Test func deleteRemovesThenRefreshes() async throws {
        harness.spies.worktrees.listResult = .success([WorktreeSample.main, WorktreeSample.feature])
        await store.refresh()

        store.delete(id: WorktreeSample.feature.id, deleteDerivedData: false, deleteBranch: true)

        #expect(store.busyIDs == [WorktreeSample.feature.id])
        try await waitUntil { store.busyIDs.isEmpty }
        #expect(harness.lastActivity?.title == "Removed worktree")
    }
}
```

- `async` store methods: `await` them. Methods that start a `Task` (fire-and-forget): `try await waitUntil { … }`
  on the state or the spy calls you expect.
- An event subscription is created in the store's `init`: touch the lazy store first (`_ = harness.worktrees`), then
  post with `harness.events.post(...)`.
- Persistence: build the harness with a prepared store (`StoreHarness(store: InMemoryKeyValueStore())`), then check
  the key with `harness.store.string(forKey:)`.

## Fixtures and samples

- `Fixtures/<Thing>Fixture.swift`: an `enum` with `static let` inputs (command output text, JSON, domain values).
  Every target has its own `Fixtures/` folder.
- `Stores/Samples/<Thing>Sample.swift`: domain values for store tests (`ProjectSample.app`, `WorktreeSample.feature`).
  Same shape, a separate name so mapper fixtures and store samples do not collide.
- A fixture with a secret uses a fake value and the test checks that the value is absent from every output field.

## Files and processes

- `TemporaryDirectory()` creates a unique folder and removes it in `deinit`. `write(_:to:)` creates parent folders;
  `path(_:)` gives a path inside. Never write to the real home folder, `/tmp` paths by hand, or `UserDefaults.standard`
  (`UserDefaults(suiteName:)` for `UserDefaultsKeyValueStore`).
- Integration suites in `Tests/DevHubDataTests/Integration/`: `@Suite(.tags(.integration)) struct
  <Type>IntegrationTests`. Both the tag and the name are required: `swift test` cannot skip by tag, so
  `Scripts/test.sh --skip integration` skips by the name. `.integration` is declared in
  `DevHubDataTests/Support/Tag+Integration.swift`.
- `GhIntegrationTests` reads a real GitHub repository through `gh`. It runs only with
  `DEVHUB_PLAYGROUND=owner/repo Scripts/test.sh --filter GhIntegrationTests` and is skipped otherwise.
  The repository needs open pull requests, one of them with an open review thread, and one merged
  pull request. The suite only reads: it never approves, merges or writes.
- `TemporaryGitRepository` (`DevHubDataTests/Support/`) runs `git init -b main`, two commits, branches `feature` and
  `merged-branch`, and a linked worktree `linked`, through a real `ShellRunner` with a `SpyCommandRecorder`.

## `waitUntil`

`try await waitUntil { condition }` checks the condition on the main actor, yields between checks and throws
`TestError.timedOut` after the timeout (10 s by default). It replaces every `Task.sleep` in a test. The default was
2 s; in a parallel run many store tests waited longer than that for the main-actor queue (see Running).

## What not to test, and why

- SwiftUI views, `AppWindows`, `RootView`: no logic left in them (the mappers hold it); a snapshot setup is not worth
  it for a personal app. The preview is the check.
- Text from `relativeDescription`, `ByteFormat`, `Countdown`, `ByteCountFormatter`: it depends on the locale and the
  clock. Assert nil or not empty only.
- Methods that call `NSWorkspace`, `NSApp` or `SMAppService` directly: they change the real Mac.
- `XcodeDerivedDataRepository`: its root is not injectable yet (`docs/STATUS.md`). `ContainerLocator.find(…devicesRoot:)` takes a root; `SimulatorContainerTree` (`DevHubDataTests/Support/`) builds a fake simulator data container.
- Behaviour that looks wrong: pin it as it is, and add it to the known gaps of `docs/STATUS.md`. Fix it in a separate
  change that also updates the test.

## Add a test for…

| New code | Test file | What to pin |
|---|---|---|
| a mapper | `DevHubPresentationTests/Mappers/<Feature>/<Row>MapperTests.swift` | one `@Test` per input state: icon, tint, text, hint, tags, enabled flags; grouping and order for a sections mapper |
| a store action | `DevHubPresentationTests/Stores/<Feature>/<Name>StoreTests.swift` (+ `lazy var` in `StoreHarness`) | the spy calls in order, state before and after, posted events, activity line, failure path |
| a parser | `DevHubDataTests/<Folder>/<Parser>Tests.swift` + `Fixtures/<Thing>Fixture.swift` | every field of the parsed value, empty input, malformed input |
| a policy | `DevHubDomainTests/Policies/<Policy>Tests.swift` | a table of inputs and decisions, every branch |
| a use case | `DevHubDomainTests/UseCases/<Name>UseCaseTests.swift` | exact port calls per path over `Ports.spies()`, the result, the error path, cancellation for streams |
| a repository that runs git or sh | `DevHubDataTests/Integration/<Type>IntegrationTests.swift` | the parsed result over `TemporaryGitRepository`, the recorded commands |
| a formatter | `DevHubUITests/Formatters/<Formatter>Tests.swift` | exact text when it does not depend on locale or clock |

Then `Scripts/test.sh` and `Scripts/build.sh` (the lint checks the test files too).
