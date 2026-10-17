---
paths:
  - "Packages/DevHubKit/Tests/**"
  - "Packages/DevHubKit/Sources/DevHubTestSupport/**"
---

# Testing rules

Full guide with more examples: `/testing`.

## Shape

- Swift Testing only: `import Testing`, `@Suite struct <Type>Tests`, `@Test func …`, `#expect`, `#require`.
- One suite per type under test, file `<Type>Tests.swift`. Folders mirror `Sources/<Module>/`. An extension under
  test gets a suite named without the `+`: `String+Shell` is tested by `StringShellTests`.
- `@testable import <Module>` for the module under test; plain `import` for `DevHubTestSupport`, `DevHubDomain`.
- The code rules apply: no comments, `== false`, one type per file (a `private` helper under ~30 lines may stay in
  the test file; a shared fake goes to `Support/` or to `DevHubTestSupport`). `Scripts/check-layers.sh` checks Tests.

## Inputs

- Ports: `let (ports, spies) = Ports.spies()`. Each `Spy<Port>` records `calls` in order and has scripted
  `*Result` and `*Error` properties. A new port gets a new spy, a `PortSpies` field and a line in `Ports+Spies.swift`.
- Persistence: `InMemoryKeyValueStore()` from DevHubMocks.
- Fixtures: `static let` values in `Fixtures/<Thing>Fixture.swift` enums. Store tests use
  `Stores/Samples/<Thing>Sample.swift`.
- Files on disk only through `TemporaryDirectory` (created in `init`, removed in `deinit`).

## Rules

- No `Task.sleep`. Await fire-and-forget work with `try await waitUntil { … }` (fails after 10 s).
- Assert on domain values, tints, icons, enabled flags and exact command lists. Never assert on locale or clock text
  (`relativeDescription`, `ByteFormat`, `Countdown`, `ByteCountFormatter`) beyond nil or not empty.
- Pin current behaviour. When a test shows a bug, write it down in `docs/STATUS.md` and fix it in its own change.
- Integration suites run real processes (`git`, `sh`). They carry `.tags(.integration)` and the name ends in
  `IntegrationTests`. `swift test` cannot skip by tag; `Scripts/test.sh --skip integration` skips by the name.

## Examples

A use case over a spy:

```swift
@Suite struct RebaseOnBaseUseCaseTests {
    @Test func fetchesTheBaseThenRebasesWithAutostash() async throws {
        let (ports, spies) = Ports.spies()

        try await RebaseOnBaseUseCase(git: ports.git).execute(baseName: "dev", baseRef: "origin/dev", checkoutPath: "/repo")

        #expect(spies.git.calls == [
            .perform(.fetchRef("dev"), path: "/repo"),
            .perform(.rebase(onto: "origin/dev", autostash: true), path: "/repo"),
        ])
    }
}
```

A store over `StoreHarness` (`Tests/DevHubPresentationTests/Stores/Support/`):

```swift
@Suite struct WorktreesStoreTests {
    private let harness = StoreHarness()

    @Test func branchesChangedRefreshes() async throws {
        _ = harness.worktrees
        harness.events.post(.branchesChanged)

        try await waitUntil { harness.spies.worktrees.calls.contains(.list(projectPath: ProjectSample.path)) }
    }
}
```

An integration suite:

```swift
@Suite(.tags(.integration)) struct ShellRunnerIntegrationTests {
    private let recorder = SpyCommandRecorder()

    @Test func capturesStdoutAndExitCode() async throws {
        let result = try await ShellRunner(recorder: recorder).run("/bin/echo", ["hello"], cwd: nil)

        #expect(result.stdout == "hello\n")
        #expect(result.exitCode == 0)
    }
}
```

Run: `Scripts/test.sh`, `Scripts/test.sh --skip integration`, `Scripts/test.sh --filter WorktreesStoreTests`.
