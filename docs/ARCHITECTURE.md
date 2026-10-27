# DevHub architecture

This document is the contract for every change in `Packages/DevHubKit/` and `DevHub/`. The short version lives in
`.claude/rules/`; this file holds the full rules and the reasons. When the code and this file disagree, fix one of
them in the same session.

## 1. Layers and modules

Four layers, one direction:

```
Composition  →  Presentation  →  Domain  ←  Data
                     ↓
                    UI
```

Each layer is a module of the local Swift package `Packages/DevHubKit` (tools 6.2, Swift 6 language mode). The
compiler checks the direction: a module can only import the modules it lists in `Package.swift`.

| Module | Depends on | Default isolation | Holds |
|---|---|---|---|
| `DevHubDomain` | nothing | nonisolated | models, values, ports, policies, use cases, errors, `Ports`, `UseCases` |
| `DevHubData` | Domain | nonisolated | live repositories, runners, parsers, `Ports.live(shell:)` |
| `DevHubMocks` | Domain | nonisolated | `Mock*Repository`, `MockData`, `InMemoryKeyValueStore`, `Ports.mock()` |
| `DevHubUI` | nothing | MainActor | shared SwiftUI blocks, `Theme`, `Tint`, `TagModel`, formatters, hints |
| `DevHubPresentation` | Domain, UI, Mocks | MainActor | stores, row models and mappers, views, events, `PresentationAssembly`, `AppWindows` |
| `DevHubComposition` | Domain, Data, Mocks, Presentation | MainActor | `AppContainer` (the only product) |
| `DevHubTestSupport` | Domain | nonisolated | spies and test helpers, not a product |

- Every target turns on the upcoming features `MemberImportVisibility`, `InferIsolatedConformances` and
  `NonisolatedNonsendingByDefault`. These are the same flags Xcode passes to the app target.
- Presentation imports `DevHubMocks` in one file only: `Shared/PresentationAssembly+Preview.swift`.
- The app target `DevHub` is `DevHub/DevHubApp.swift` plus `Assets.xcassets`. It links the product
  `DevHubComposition`. `project.pbxproj` holds the local package reference. The `DevHub/` folder is synchronized:
  never edit file lists in `project.pbxproj`.

`Scripts/check-layers.sh` adds the rules the compiler cannot check (section 9). `Scripts/build.sh` runs it first.

## 2. Folder map

```
DevHub.xcodeproj                 app target DevHub, Swift 6, links DevHubComposition
DevHub/
  DevHubApp.swift                @main, empty Settings scene, AppContainer as the app delegate
  Assets.xcassets
Packages/DevHubKit/
  Package.swift
  Sources/
    DevHubDomain/
      Models/ Values/ Repositories/ Policies/ UseCases/ Errors/
      Assembly/                  Ports (the 21 ports), UseCases (the 16 use cases)
    DevHubData/
      Shell/                     ShellRunner, ShellResult, LineBatcher, CommandFormatter, ISO8601
      Persistence/               UserDefaultsKeyValueStore
      Git/ (+ Parsers/) Simulators/ Build/ Claude/ Logs/ Network/ (+ MockServer/ MockSets/) Config/
                                 live repositories, runners, parsers, private DTOs
      Workspace/                 NSWorkspace, Accessibility, Carbon (AppKit allowed here only), GlobalHotKey
      Assembly/                  Ports+Live
    DevHubMocks/                 Mock*Repository, MockData+<Domain>, Persistence/InMemoryKeyValueStore, Ports+Mock
    DevHubUI/                    components one per file, Theme, Tint, Tint+Color, TagModel, CopyOnClick,
                                 FolderPicker, EnvironmentValues+CopyToPasteboard, Formatters/, Hint/
    DevHubPresentation/
      Shared/                    ProjectSession, Navigator, ActivityLog, Toaster, PasteboardWriter, OutputPanelState,
                                 SettingsStore, WindowLayout, CommandLog, CommandLogRecorder, ActionRunner, RefreshTask,
                                 AppActions, WorkspaceActions, PreferenceKeys, ConfigStore, lookup protocols (BuildLookup, …),
                                 PresentationAssembly (+Preview), View+Inject, View+PreviewEnvironment
      Shared/Events/             AppEvent, AppEvents, SubscriptionToken
      Shell/                     AppWindows, RootView, HeaderView, FooterView, MenuBarPanel, Feature, FeatureID,
                                 FeatureRegistry, drag and resize
      Features/<Name>/           <Name>Store.swift, Models/ (<Row>Model, <Row>Mapper), Views/ (one view per file)
      Features/ConfigActions/    ConfigActionsStore (+Execution, +Directives): runs `.devhub` actions for every placement;
                                 shared views ConfigActionBar, ConfigActionMenuItems, ConfigActionPrompt, ConfigActionResults
    DevHubComposition/           AppContainer, Debug/DebugLaunch (Debug builds only)
    DevHubTestSupport/           Spy<Port> for every port, PortSpies, Ports+Spies, TemporaryDirectory, WaitUntil, TestError, CallbackRecorder
  Tests/
    DevHubDomainTests/ DevHubDataTests/ DevHubUITests/ DevHubPresentationTests/
```

## 3. Access and imports

- `package` on every type and member that another module uses: types, members, nested types, `static let`
  constants, protocol witnesses (`package var body`, `package func list(...)`), `package extension`.
- No keyword (internal) for what one module uses alone. `private` as usual.
- `public` only in `DevHubComposition`: `public final class AppContainer` and `public static func live()`.
- A struct that another module builds gets an explicit `package init(...)`. It lists the stored properties in
  declaration order. When a stored property has a default value, the parameter keeps the same default. This is the
  one exception to "no default parameter values": it copies the memberwise init, which is internal.
- Protocol requirements carry no access keyword; they take the protocol's access.
- `MemberImportVisibility`: every file that uses a member from another module imports that module
  (`import DevHubDomain` for `.trimmed`, `import DevHubUI` for `.hint` and `.copyOnClick`).
- Domain, Data and Mocks never write `nonisolated` on a type: it is the module default. Members of actors and of
  MainActor classes still may (`nonisolated func run` in `ShellRunner`).
- Never fix an isolation error with `MainActor.assumeIsolated` or `@unchecked Sendable`. `@unchecked Sendable` is
  only for a class that guards its own state with a lock, a queue or a thread-safe system object (the spies,
  `InMemoryKeyValueStore`, `UserDefaultsKeyValueStore`, `LineBatcher`).

## 4. Domain

- Models are value types with `let id`, `var` fields and an enum for state. No `Color`, no SF Symbol names chosen
  by the app, no display strings. A string that comes from user data (a script title, an icon name from a JSON file)
  is data and may stay.
- Values wrap one concept with its rules: `BranchName` (strips `origin/`, knows the default base ref),
  `ProjectPath` (expands and abbreviates `~`). Use them instead of string helpers.
- Ports are protocols named `<Thing>Repository` or by verb for services (`XcodeAttaching`, `WorkspaceOpening`,
  `ProjectDetecting`, `CommandRecording`, `KeyValueStore`). Methods are `async throws`. Long work returns
  `AsyncThrowingStream` or takes an `onEvent` closure. A port never exposes command arguments, exit codes or raw
  output. Typed commands (`GitCommand`) describe intent; Data turns them into arguments.
- Policies are pure: `enum XPolicy { static func … }`. No port, no clock, no side effect.
- Use cases are `struct XUseCase: Sendable` holding ports as `let` properties with one entry point. A use case
  exists only for a rule, a multi-step sequence or two or more ports. A one-step action is not a use case; the
  store calls the port. Use cases never log, toast, navigate or touch UI state.
- Errors are `LocalizedError` enums, one per file. The message tells the user what to do next.

## 5. Data and Mocks

- A live implementation is named by its technology: `ShellGitRepository`, `SimctlSimulatorRepository`,
  `XcodeBuildRepository`, `GlabPullRequestRepository`, `AnthropicUsageRepository`, `FileMockSetRepository`.
- Every repository takes what it needs in `init` (`ShellRunner`, another port, a file root, a `KeyValueStore`). No
  repository builds another repository. No `.shared`, no static service with side effects.
- File roots are injected so tests can use a temporary folder: `FileMockSetRepository(root:)`,
  `ClaudeTranscriptSessionRepository(root:)`, `UserDefaultsKeyValueStore(defaults:)`.
- Every process goes through `ShellRunner`, which reports every command to a `CommandRecording`. Never `Process`
  outside `ShellRunner.swift`. Shared runners: `GitCommandRunner`, `SimctlRunner`, `PlistReader`, `ISO8601`.
- Parsers are pure types in their own file: text in, values out (`GitStatusParser`, `Git/Parsers/GitLogParser`,
  `GlabPullRequestParser`, `ClaudeTranscriptParser`, `HTTPRequestParser`, …). DTOs are `private`. A Domain model
  is never `Decodable` for an external format. One exception: the `.devhub/` config models in
  `DevHubDomain/Models/Config/` are `Codable`, because the user writes that JSON for DevHub and `docs/extensions.md`
  defines it. About 35 DTOs that mirror them one to one would add nothing. The decoding and the layer merge are pure
  policies (`ConfigDecoding`, `ConfigMergePolicy`). A parser that needs the clock takes it (`ClaudeUsageParser
  .parse(_:plan:now:)`).
- `UserDefaults` only in `UserDefaultsKeyValueStore.swift`. AppKit only in `DevHubData/Workspace/`.
- Mocks live in `DevHubMocks`: `Mock<Thing>Repository` (internal, one per file) return `MockData`; `Ports.mock()`
  builds them all. Previews and `PresentationAssembly.preview()` depend on them.

## 6. Presentation and UI

### Stores

- One `@Observable final class <Name>Store` per feature (MainActor by module default). It owns the feature state
  and every mutation: lists, selection, loading flags, busy IDs, expanded IDs.
- A store receives in `init`: ports, use cases, shared objects (`ProjectSession`, `ActivityLog`, `AppEvents`,
  `KeyValueStore`) and lookup protocols for state owned by another feature.
- A store never holds another feature's concrete store. Reads go through a lookup protocol in `Shared/`
  (`WorktreeLookup`, `SimulatorLookup`, `IdentityLookup`, `CheckoutContext`). Changes go through a use case; the
  owning store refreshes on an `AppEvent`.
- A store never holds raw command arguments, never reads `UserDefaults`, never calls a static service, never
  imports SwiftUI. Text for the activity log is allowed; text for a row is not.
- `ActionRunner` for "busy title, run, log, refresh, post" sequences; `RefreshTask` for refreshes (latest wins). No
  `guard isLoading == false`. Every failure goes to `ActivityLog.log(_:detail:outcome:)`.

### Events

`AppEvents` (in `Shared/Events/`) carries "something changed" between stores. A store posts when it changed data
another feature shows; interested stores subscribe in `init` and keep the `SubscriptionToken`. Add a case only when
a second store needs to react. A refresh posts only when the data changed. A store ignores the echo of its own post.

### Row models, mappers, views

- `Features/<Name>/Models/<Row>Model.swift` is a plain `struct: Identifiable, Equatable` with display strings,
  `Tint`, icon names, enabled flags, tags and warnings, plus `static let preview`. `<Row>Mapper.swift` is a pure
  `static func model(for:…)`. Colour, icon, label and hint are chosen in the mapper, never in `body`. Sorting and
  grouping live in the store or the mapper.
- One view per file under `Views/`. A row takes a model plus closures; it reads `Toaster` and `AppActions` at
  most. Cross-feature actions are methods on `AppActions`.
- `.devhub` actions in a row: the screen builds `ConfigActionItemMapper.models(for: configActions.actions(for: placement), isRunning:)`
  and passes them to the row mapper (`configActions:`). The row shows `ConfigActionMenuItems(items:onRun:)` in its
  menu and calls `onConfigAction(id)`. The screen calls `ConfigActionsStore.request(id:item:slot:)` with the row
  context and draws `ConfigActionPrompt` under the row for the slot `<placement>:<row id>`. A bar or a toolbar uses
  `ConfigActionBar(placement:item:)`.
- Copy: `Toaster.copy(_:label:)` writes through `PasteboardWriter` (the only file with `NSPasteboard`).
  `CopyOnClick` in DevHubUI calls `\.copyToPasteboard`, which `inject` sets to `toaster.copy`.

### DevHubUI

DevHubUI imports nothing from the package (SwiftUI, AppKit, Foundation, Observation only). Every component is
`package` with `package var body` and an explicit `package init`. Inputs that would need a Domain type come in as
plain values: `FolderPicker.chooseFolder(directory:prompt:message:)` takes a `URL` and two strings. Components:
`RowContainer`, `InlineConfirmation`, `ListState`, `ListMessage`, `ToolbarBar`, `ListSectionHeader`,
`LinkButtonStyle`, `FieldLabel`, `Tag`, `ModelTag`, `TagModel`, `IconTile`, `IconButton`, `OverflowMenu`,
`PanelCard`, `SectionHeader`, `SearchField`, `StatusDot`, `ActionBar`, `FlowLayout`. Formatters in `Formatters/`.
The UI rules are in `/ui-components`.

## 7. Composition

| Piece | Module | What it does |
|---|---|---|
| `Ports` | Domain `Assembly/Ports.swift` | struct with the 21 ports |
| `Ports.live(shell:)` | Data `Assembly/Ports+Live.swift` | builds every live repository once, passes file roots |
| `Ports.mock()` | Mocks `Ports+Mock.swift` | builds every mock |
| `UseCases(ports:)` | Domain `Assembly/UseCases.swift` | builds the 16 use cases |
| `PresentationAssembly(ports:useCases:store:commandLog:projects:selectedProjectID:settings:recentEvents:)` | Presentation `Shared/` | builds every shared object and store, in order |
| `PresentationAssembly.preview()` | Presentation `Shared/PresentationAssembly+Preview.swift` | mocks, `InMemoryKeyValueStore`, `MockData` sample state |
| `View.inject(_:)`, `View.previewEnvironment()` | Presentation `Shared/` | put the assembly into the environment; previews call `.previewEnvironment()` |
| `AppWindows(assembly:)` | Presentation `Shell/` | status item, panel, pinned window; hosts `RootView().inject(assembly)` |
| `AppContainer` (`init()`, `applicationDidFinishLaunching`) | Composition | `CommandLog`, `CommandLogRecorder`, `ShellRunner(recorder:)`, `Ports.live`, `UseCases`, `UserDefaultsKeyValueStore(defaults: .standard)`, saved projects and settings, `PresentationAssembly`, then `AppWindows` and `GlobalHotKey`; in Debug builds `DebugLaunch` reads the `DEVHUB_*` switches |

Factories live next to the concrete types, so the concrete inits stay internal to their module. Adding a
repository, a use case or a store is one line in the matching factory. There are no singletons.

## 8. Tests

- Swift Testing in four targets: `DevHubDomainTests`, `DevHubDataTests` (with integration suites),
  `DevHubUITests`, `DevHubPresentationTests` (shared objects, mappers, stores). About 1,570 tests, about 3 s.
- `Scripts/test.sh` runs `swift test -q` on the package and prints one summary line; the exit code is forwarded.
  `Scripts/test.sh --skip integration` skips the process suites; `Scripts/test.sh --filter <Suite>` runs one suite.
- `DevHubTestSupport`: one `Spy<Port>` per port (calls in order, scripted `*Result` and `*Error` properties),
  `Ports.spies()` returning `(ports, spies)`, `TemporaryDirectory`, `waitUntil(timeout:_:)`, `TestError`.
- Conventions: `@Suite struct <Type>Tests`, one per type, file `<Type>Tests.swift`, folders mirror `Sources/`;
  `@testable import <Module>`; fixtures in `Fixtures/<Thing>Fixture` enums (store tests use
  `Stores/Samples/<Thing>Sample`); files on disk only through `TemporaryDirectory`; no `Task.sleep`, `waitUntil`
  for fire-and-forget work; never assert on locale or clock text (`relativeDescription`, `ByteFormat`,
  `Countdown`, `ByteCountFormatter`).
- Integration suites run real processes. They carry `.tags(.integration)` and their name ends in
  `IntegrationTests`. `swift test` cannot skip by tag, so `test.sh` skips by the name.
- The code rules apply to tests too: no comments, `== false`, one type per file (a private helper under about 30
  lines may stay in the test file). Full guide: `/testing`.

## 9. Lint and files

`Scripts/check-layers.sh` checks what the compiler does not:

- Domain imports no UI framework and touches no system API. Data imports no SwiftUI; AppKit only in
  `DevHubData/Workspace/`. Mocks import no UI framework. DevHubUI imports no DevHub module.
- Presentation imports no `DevHubData`, and `DevHubMocks` only in `PresentationAssembly+Preview.swift`.
- Network.framework (`import Network`, `NWListener`, `NWConnection`) only under `DevHubData/Network/MockServer/`.
- `.shared` singletons are forbidden (system objects such as `NSWorkspace.shared` are allowed). `Process(` only in
  `ShellRunner.swift`. `UserDefaults` only in `UserDefaultsKeyValueStore.swift`. `NSPasteboard` only in
  `PasteboardWriter.swift`.
- No column-0 `nonisolated` in Domain, Data, Mocks. `public` only in `DevHubComposition`. `@testable` only under
  `Tests/`. `DevHub/` holds no Swift file except `DevHubApp.swift`.
- The file rule over `Sources/` and `Tests/`: one top-level type per file, the file name is the type name, an
  extension of another type lives in `<Type>+<Concern>.swift`. Allowed by case: a `private` helper under about 30
  lines, a protocol with one trivial implementation, a `private enum Keys`, extensions of the file's own type.
  Anything else goes into `Scripts/layer-exceptions.txt` (empty today) with a reason, as
  `Packages/DevHubKit/Sources/<Module>/<File>.swift`.
- A file over about 300 lines is a sign to split out a row, a panel, a mapper or a policy.

## 10. Naming

| Thing | Pattern | Example |
|---|---|---|
| Port | `<Thing>Repository`, verb for services | `WorktreeRepository`, `XcodeAttaching` |
| Live implementation | `<Technology><Thing>Repository` | `ShellWorktreeRepository` |
| Mock | `Mock<Thing>Repository` | `MockWorktreeRepository` |
| Spy | `Spy<Port>` | `SpyWorktreeRepository` |
| Use case | `<Verb><Thing>UseCase` | `RemoveWorktreeUseCase` |
| Policy | `<Thing>Policy` or a noun | `WorktreeCleanupPolicy`, `RepositoryWebLinks` |
| Store | `<Feature>Store` | `WorktreesStore` |
| Lookup | `<Thing>Lookup` | `WorktreeLookup` |
| Row model and mapper | `<Row>Model`, `<Row>Mapper` | `WorktreeRowModel`, `WorktreeRowMapper` |
| Error | `<Thing>Error` | `WorktreeError` |
| Test suite | `<Type>Tests`, `<Type>IntegrationTests` | `WorktreeRowMapperTests` |

## 11. How to

### Add a feature

1. Model in `DevHubDomain/Models/`, `package struct` with an explicit `package init`.
2. Port in `DevHubDomain/Repositories/`, `package protocol … : Sendable`.
3. Mock in `DevHubMocks/` with `MockData+<Domain>.swift`; live repository in `DevHubData/<Domain>/` with a parser in
   its own file.
4. A field in `Ports` (and its `package init`), one line in `Ports.live(shell:)`, one in `Ports.mock()`, one in
   `Ports.spies()` and `PortSpies` with a new `Spy<Port>` in `DevHubTestSupport`.
5. A use case only if there is logic: `DevHubDomain/UseCases/`, one line in `UseCases(ports:)`.
6. `DevHubPresentation/Features/<Name>/<Name>Store.swift`; one property and one line in `PresentationAssembly`, one
   `.environment(...)` line in `View+Inject`; sample state in `preview()` when the mock is not enough.
7. `Models/<Row>Model.swift`, `<Row>Mapper.swift`; `Views/` one file per view, each with a `#Preview`.
8. A case in `FeatureID`, one line in `FeatureRegistry.all`.
9. Tests: `<Row>MapperTests` and `<Name>StoreTests` in `DevHubPresentationTests`, a parser test in
   `DevHubDataTests`, a use case test in `DevHubDomainTests`. Add the store to `StoreHarness`.
10. `Scripts/build.sh` and `Scripts/test.sh` clean, then `/update-docs`.

### Add a repository method

Port first, then the mock, the spy (a `Call` case and a scripted result), the live implementation, then the caller.
The port never leaks arguments or output. Test the parser and the spy-driven caller.

### Add a use case

Write the policy first if a pure rule can be separated. The use case takes ports as `let` properties and returns a
result. Add it to `UseCases(ports:)`; pass it to the store in `PresentationAssembly` and `StoreHarness`. Test it
over `Ports.spies()`. The store calls it, logs the outcome and posts an event.

### Add a cross-feature action

A method on `AppActions`. It switches the tab through `Navigator` and calls the store. Rows call that method.

## 12. Why

- Modules, not folders: the compiler enforces the direction, and each layer builds and tests alone with
  `swift test`. The lint keeps only the rules the compiler cannot express.
- `package`, not `public`: the package is the only user of its modules. `public` marks the one entry point of the
  app.
- Factories next to the concrete types: `Ports.live` lives in Data, so the live repositories stay internal.
- Use cases only where there is logic: a trivial use case per port method would double the file count for nothing.
- Lookup protocols instead of concrete stores: a store can be built with a spy for a test or a mock for a preview,
  and the dependency graph stays one way.
- Row models: a row with a model is a pure function of its input, previewable alone, and its mapper is easy to test.
- No singletons: every object is built once, so previews, tests and the live app differ only in the ports.
