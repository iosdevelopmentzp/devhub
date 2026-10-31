---
paths:
  - "Packages/DevHubKit/Sources/DevHubPresentation/**"
  - "Packages/DevHubKit/Sources/DevHubUI/**"
---

# Presentation and UI rules

## Modules

- DevHubPresentation depends on DevHubDomain, DevHubUI and DevHubMocks. Every file imports `DevHubDomain` and
  `DevHubUI` when it uses them. `import DevHubMocks` only in `Shared/PresentationAssembly+Preview.swift`. Never
  `import DevHubData`; never `UserDefaults`, `Process` or `NSPasteboard` (only `Shared/PasteboardWriter.swift`).
- DevHubUI depends on nothing in the package: SwiftUI, AppKit, Foundation, Observation only. A component that would
  need a Domain type takes plain values instead (`FolderPicker.chooseFolder(directory:prompt:message:)`).
- MainActor is the module default in both. Stores, row models, mappers and views stay internal; tests reach them with
  `@testable import DevHubPresentation`. `package` only on what Composition uses (`PresentationAssembly` and its
  init, `AppWindows`, `SettingsStore` members, `CommandLog`, `CommandLogRecorder`, `PreferenceKeys`).
- DevHubUI is used by another module, so every component is `package`: the type, `package init`, `package var body`,
  `package static` tokens in `Theme`, formatters, `Tint.color`, `@Entry package var`.

```swift
package struct StatusDot: View {
    package let color: Color

    package init(color: Color) {
        self.color = color
    }

    package var body: some View {
        Circle().fill(color).frame(width: 7, height: 7)
    }
}
```

## Composition

- `PresentationAssembly` (`Shared/`) builds every shared object and store, in order. A new store is one property and
  one line there, one `.environment(...)` line in `View+Inject.swift`, and one `lazy var` in the tests' `StoreHarness`.
- `PresentationAssembly.preview()` builds the same graph over `Ports.mock()`, `InMemoryKeyValueStore` and `MockData`.
  A screen preview calls `.previewEnvironment()`.
- `inject(_:)` also sets `\.copyToPasteboard` to `toaster.copy`, so `CopyOnClick` in DevHubUI needs no `Toaster`.
- `AppWindows(assembly:)` (`Shell/`) owns the status item, the panel and the pinned window. See `/panel-window`.

## Store

```swift
@MainActor
@Observable
final class WorktreesStore: WorktreeLookup {
    private(set) var worktrees: [Worktree] = []
    private(set) var busyIDs: Set<Worktree.ID> = []

    @ObservationIgnored private let repository: any WorktreeRepository
    @ObservationIgnored private let removeWorktree: RemoveWorktreeUseCase
    @ObservationIgnored private let session: ProjectSession
    @ObservationIgnored private let activity: ActivityLog
    @ObservationIgnored private let events: AppEvents
    @ObservationIgnored private let refreshTask = RefreshTask()

    init(repository: any WorktreeRepository, removeWorktree: RemoveWorktreeUseCase, session: ProjectSession, activity: ActivityLog, events: AppEvents) { … }

    func refresh() async {
        await refreshTask.run { [weak self] in
            guard let self else { return }
            let loaded = try await repository.list(projectPath: session.selectedProject.path)
            try Task.checkCancellation()
            guard loaded != worktrees else { return }
            worktrees = loaded
            events.post(.worktreesChanged)
        }
    }
}
```

- A store owns UI state and every mutation of it. It calls ports directly for one-step actions and use cases for
  logic. It logs to `ActivityLog`, posts and subscribes to `AppEvents`, persists through `KeyValueStore`.
- Never another feature's concrete store. Read through a lookup protocol (`WorktreeLookup`, `SimulatorLookup`,
  `IdentityLookup`, `CheckoutContext` in `Shared/`). Change through a use case, refresh through an event.
- Never raw command arguments, never `UserDefaults`, never a static service, never `import SwiftUI`.
- Every store action and refresh has a test in `Tests/DevHubPresentationTests/Stores/` over spies.
- `ActionRunner` for busy-title command sequences, `RefreshTask` for refreshes. No `guard isLoading == false`.
- Post an event only when data changed. Do not react to the echo of your own post.

## Row model and mapper

```swift
struct WorktreeRowModel: Identifiable, Equatable {
    let id: Worktree.ID
    var title: String
    var icon: String
    var iconTint: Tint
    var statusTags: [TagModel]
    var canDelete: Bool
    var deleteWarnings: [String]

    static let preview = WorktreeRowModel(…)
}

enum WorktreeRowMapper {
    static func model(for worktree: Worktree, baseBranch: BranchName, derivedDataSize: Int64?, isBuildSource: Bool) -> WorktreeRowModel
}
```

- The screen builds models from its store and lookups; the row renders one. Colour, icon, label and hint are chosen in
  the mapper from domain values, policies and formatters. Sorting, grouping and filtering live in the store or the
  mapper.

## View

- One view per file in `Views/`. A row takes a model and closures; its `@State` is confirmation or editing input only
  (hover comes from `RowContainer`). Constant styling (a fixed tint on a button, a warning icon) may stay in the view;
  a choice made from domain state may not.
- A screen reads its store, `ProjectSession`, `AppActions` and the lookups it needs to build its models (`SimulatorsView` reads five). A row reads `Toaster` and `AppActions` at most; everything else arrives as a model or a closure.
- Cross-feature actions go through `AppActions` (`appActions.buildAndRun(worktreeID:)`). Never `navigator.show` plus a
  store call in one closure.
- Formatting through `DevHubUI/Formatters/` (`Date+RelativeDescription`, `ByteFormat`, `CountText`,
  `DurationFormat`, `SyncText`, `LogTimestamp`, `ClockTime`, `Countdown`). No `DateFormatter` in a view or a mapper.
- Colours through `Theme` and `Tint`. Components from `DevHubUI` (`RowContainer`, `InlineConfirmation`,
  `ListState`, `ListMessage`, `ToolbarBar`, `ListSectionHeader`, `LinkButtonStyle`, `FieldLabel`, `Tag`, `ModelTag`,
  `TagModel`, `IconButton`, …). See `/ui-components`.
- Every screen and every row ends with `#Preview`. A row preview uses `<Row>Model.preview`; a screen preview uses
  `.previewEnvironment()`.
