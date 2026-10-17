---
paths:
  - "Packages/DevHubKit/Sources/DevHubData/**"
  - "Packages/DevHubKit/Sources/DevHubMocks/**"
---

# Data and Mocks rules

## DevHubData

- Implements Domain ports. Depends on DevHubDomain only; every file starts with `import Foundation` and
  `import DevHubDomain`. AppKit only under `DevHubData/Workspace/`. Never SwiftUI or Observation.
- Nonisolated is the module default: never write `nonisolated` on a type. A member of an actor may be `nonisolated`
  (`ShellRunner.run`).
- Access: the live repositories, runners and parsers stay internal. `package` only on what Composition or the tests
  need from outside: `Ports.live(shell:)`, `ShellRunner.init(recorder:)`, `UserDefaultsKeyValueStore.init(defaults:)`,
  `GlobalHotKey`. Tests reach the rest with `@testable import DevHubData`.
- Named by technology: `Shell<Thing>Repository` (git, files), `Simctl<Thing>Repository`, `Xcode<Thing>Repository`,
  `Glab<Thing>Repository`, `Anthropic<Thing>Repository`, `File<Thing>Repository`.
- Everything a repository needs comes through `init`, including file roots. No repository builds another
  repository. No `.shared`. `Ports.live(shell:)` (`Assembly/Ports+Live.swift`) builds every repository once.

```swift
struct ShellWorktreeRepository: WorktreeRepository {
    let git: GitCommandRunner

    init(shell: ShellRunner) {
        git = GitCommandRunner(shell: shell)
    }
}

struct FileMockSetRepository: MockSetRepository {
    let root: URL
}
```

- Every process goes through `ShellRunner`. Never `Process` elsewhere. Never on the main actor.
- Use the shared runners instead of private wrappers: `GitCommandRunner`, `SimctlRunner`, `PlistReader`, `ISO8601`.
- Parsers are pure types in their own file: text in, values out (`Git/Parsers/GitLogParser`, `GlabMergeRequestParser`,
  `HTTPRequestParser`, …). A parser that needs the clock takes it as a parameter. DTOs are `private` to the parser.
  A Domain model is never `Decodable` for an external format; map DTO → model explicitly.
- Raw stderr becomes the `.command(String)` case of the domain error, trimmed. Tolerated exit codes are explicit
  (`simctl boot` 149 means "already booted").
- `UserDefaults` only inside `UserDefaultsKeyValueStore`. Everything else takes a `KeyValueStore`.
- Secrets: a token is read for one request and dropped. `security` output is never recorded. Log lines pass through
  `LogRedactor` before they leave the repository.
- Every parser and encoder has a fixture test in `Tests/DevHubDataTests/`. Code that reads files is tested over
  `TemporaryDirectory`; code that runs git or `sh` has an `…IntegrationTests` suite.

## DevHubMocks

- Depends on DevHubDomain only. No UI framework.
- `Mock<Thing>Repository`, one per file, internal, returning `MockData` and sleeping a little on actions.
- `MockData` is a `package enum` split into `MockData+<Domain>.swift` files with `package static` samples.
- `InMemoryKeyValueStore` (`Persistence/`) is the `KeyValueStore` for previews and tests.
- `Ports.mock()` (`Ports+Mock.swift`) builds every mock. A new port adds one line here.
