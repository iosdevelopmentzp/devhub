# Layers

Full contract: `docs/ARCHITECTURE.md`. Read it before a change that adds a type.

All code lives in the local package `Packages/DevHubKit`, Swift 6 language mode. One module per layer; the compiler
enforces the direction `Composition → Presentation → Domain ← Data`.

| Module | Depends on | Default isolation | Holds |
|---|---|---|---|
| `DevHubDomain` | nothing | nonisolated | models, values, ports (`*Repository`), policies, use cases, errors, `Ports`, `UseCases` |
| `DevHubData` | Domain | nonisolated | live repositories, runners, parsers, `Ports.live(shell:)`; AppKit only in `Workspace/` |
| `DevHubMocks` | Domain | nonisolated | `Mock*Repository`, `MockData`, `InMemoryKeyValueStore`, `Ports.mock()` |
| `DevHubUI` | nothing | MainActor | shared SwiftUI blocks, `Theme`, `Tint`, formatters, hints |
| `DevHubPresentation` | Domain, UI, Mocks | MainActor | stores, row models, mappers, views, events, `PresentationAssembly`, `AppWindows` |
| `DevHubComposition` | Domain, Data, Mocks, Presentation | MainActor | `AppContainer` |
| `DevHubTestSupport` | Domain | nonisolated | spies and test helpers |

- Presentation imports `DevHubMocks` only in `Shared/PresentationAssembly+Preview.swift`.
- `DevHub/` (the app host) holds only `DevHubApp.swift` and `Assets.xcassets`. No `.shared` anywhere.

Access: `package` on everything another module uses (types, members, nested types, statics, `package var body`).
Internal inside a module. `public` only on `AppContainer` and `AppContainer.live()`. A struct built in another module
gets an explicit `package init` in declaration order, with the same defaults as its stored properties. A file that
uses another module's extension member imports that module. Never write `nonisolated` on a type in Domain, Data or
Mocks.

One top-level type per file; the file name is the type name. Exceptions by case: a `private` helper under ~30 lines,
a protocol with one trivial implementation, a `private enum Keys`, extensions of the file's own type. Other
extensions go to `<Type>+<Concern>.swift`. Every other exception is listed in `Scripts/layer-exceptions.txt`.

Tests: Swift Testing in `Packages/DevHubKit/Tests/`, one `<Type>Tests` suite per type, spies from
`DevHubTestSupport`. New logic comes with a test (`.claude/rules/testing.md`, `/testing`).

After every change run `Scripts/build.sh` (runs `Scripts/check-layers.sh`, then `xcodebuild`; prints `layers: ok`
and the app path) and `Scripts/test.sh` (one passing summary line). Both must be clean before a commit.
