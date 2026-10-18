---
name: add-feature
description: "Add a new screen (tab) to DevHub end to end through the package modules: Domain model, port and use case, Data repository, mock and spy, the Ports, UseCases and PresentationAssembly wiring, a feature store, row model and mapper, one file per view with hover actions, the FeatureID case and FeatureRegistry entry, View+Inject, StoreHarness and tests. Use for any 'add a screen / tab / feature / section' request."
---

# Add Feature

A feature is one tab inside the panel. It touches every module, in this order. Paths are relative to
`Packages/DevHubKit/Sources/`. The example adds a "Devices" tab. Load `data-layer` for the repository,
`add-use-case` for logic over two ports, `ui-components` for the views and `testing` for the tests. The full contract
is `docs/ARCHITECTURE.md` section 11.

A tab that only runs `.devhub` scripts needs no code: it is a custom tab in `.devhub/tabs/` (`extensions` skill).

## 1. Model: `DevHubDomain/Models/Device.swift`

A value type with `let id`, `var` fields and an enum for state. No colour, no icon, no display text. Explicit
`package init` in declaration order.

```swift
package struct Device: Identifiable, Hashable, Sendable {
    package enum State: Hashable, Sendable { case connected, disconnected }

    package let id: String
    package var name: String
    package var state: State

    package init(id: String, name: String, state: State) {
        self.id = id
        self.name = name
        self.state = state
    }
}
```

An error for the feature is one `LocalizedError` enum in `DevHubDomain/Errors/DeviceError.swift`.

## 2. Port: `DevHubDomain/Repositories/DeviceRepository.swift`

```swift
package protocol DeviceRepository: Sendable {
    func list() async throws -> [Device]
    func reconnect(id: String) async throws
}
```

The port never exposes command arguments, exit codes or raw output. Long work returns `AsyncThrowingStream` or
takes an `onEvent` closure.

## 3. Data, mock and spy

- Live: `DevHubData/<Area>/SimctlDeviceRepository.swift` (internal), named by its technology. A parser in its own
  file. Every process goes through `ShellRunner` or a shared runner (`SimctlRunner`, `GitCommandRunner`). Details:
  `data-layer`.
- Mock: `DevHubMocks/MockDeviceRepository.swift` (internal) returns `MockData.devices` from a new
  `MockData+Devices.swift` and sleeps a little on actions.
- Spy: `DevHubTestSupport/SpyDeviceRepository.swift` (`package final class … @unchecked Sendable` with a lock, a
  `Call` enum and scripted `*Result` and `*Error` properties). Copy `SpyAISessionRepository` for the shape.

## 4. Wiring of the port

One field per place. The compiler shows every place that misses it.

| File | Line |
|---|---|
| `DevHubDomain/Assembly/Ports.swift` | `package let devices: any DeviceRepository` and the `package init` parameter |
| `DevHubData/Assembly/Ports+Live.swift` | `devices: SimctlDeviceRepository(shell: shell),` |
| `DevHubMocks/Ports+Mock.swift` | `devices: MockDeviceRepository(),` |
| `DevHubTestSupport/PortSpies.swift` | `package let devices = SpyDeviceRepository()` |
| `DevHubTestSupport/Ports+Spies.swift` | `devices: spies.devices,` |

A use case only when there is a rule, a sequence or two ports: `DevHubDomain/UseCases/`, one field and one line in
`UseCases(ports:)` (`DevHubDomain/Assembly/UseCases.swift`). See `add-use-case`.

## 5. Store: `DevHubPresentation/Features/Devices/DevicesStore.swift`

```swift
import Foundation
import Observation
import DevHubDomain
import DevHubUI

@MainActor
@Observable
final class DevicesStore {
    private(set) var devices: [Device] = []
    private(set) var isLoading = false
    private(set) var error: String?
    private(set) var busyIDs: Set<Device.ID> = []

    @ObservationIgnored private let repository: any DeviceRepository
    @ObservationIgnored private let activity: ActivityLog
    @ObservationIgnored private let refreshTask = RefreshTask()
    @ObservationIgnored private var subscription: SubscriptionToken?

    init(repository: any DeviceRepository, activity: ActivityLog, events: AppEvents) {
        self.repository = repository
        self.activity = activity
        subscription = events.subscribe { [weak self] event in
            guard let self else { return }
            guard case .projectChanged = event else { return }
            Task { await refresh() }
        }
    }

    func refresh() async {
        await refreshTask.run { [weak self] in
            guard let self else { return }
            isLoading = true
            defer { isLoading = false }
            do {
                let loaded = try await repository.list()
                try Task.checkCancellation()
                devices = loaded
                error = nil
            } catch {
                try Task.checkCancellation()
                self.error = error.localizedDescription
                activity.log("Device list failed", detail: error.localizedDescription, outcome: .failure)
            }
        }
    }
}
```

Rules:

- The store owns the feature state and every mutation. It never imports SwiftUI and never holds raw command
  arguments.
- It never holds another feature's store. It reads through a lookup protocol in `Shared/` (`WorktreeLookup`,
  `SimulatorLookup`, `IdentityLookup`, `CheckoutContext`, `BuildLookup`). It changes another feature through a use
  case, and the owner refreshes on an `AppEvent`.
- `RefreshTask` for refreshes (the latest call wins), `ActionRunner` for "busy title, run, log" actions. No
  `guard isLoading == false`.
- Every failure goes to `ActivityLog.log(_:detail:outcome: .failure)`.
- A new `AppEvent` case only when a second store must react. Some stores `switch` over every case, so the compiler
  lists the stores to update.
- Saved choices go through `KeyValueStore` with a key constant in the store. Never rename a saved key.

## 6. Assembly and environment

- `DevHubPresentation/Shared/PresentationAssembly.swift`: a `let devices: DevicesStore` and one line in `init`
  after the objects it needs: `devices = DevicesStore(repository: ports.devices, activity: activity, events: events)`.
- `DevHubPresentation/Shared/View+Inject.swift`: `.environment(assembly.devices)`.
- `DevHubPresentation/Shared/PresentationAssembly+Preview.swift`: sample state when the mock is not enough
  (`assembly.devices.devices = MockData.devices` needs a non-private setter, as `WorktreesStore.worktrees` has).
- Tests: a `lazy var devices = DevicesStore(…)` in
  `Tests/DevHubPresentationTests/Stores/Support/StoreHarness.swift`, built over `ports` and `spies`.

## 7. Row model and mapper: `Features/Devices/Models/`

```swift
struct DeviceRowModel: Identifiable, Equatable {
    let id: Device.ID
    var title: String
    var icon: String
    var iconTint: Tint
    var statusTags: [TagModel]
    var canReconnect: Bool

    static let preview = DeviceRowModel(id: "A1B2", title: "iPhone 16", icon: "iphone", iconTint: .green, statusTags: [TagModel("connected", tint: .green)], canReconnect: false)
}

enum DeviceRowMapper {
    static func model(for device: Device, isBusy: Bool) -> DeviceRowModel { … }
}
```

Colour (`Tint`), icon, label and hint are chosen in the mapper, never in `body`. Sorting and grouping live in the store
or in a sections mapper (`WorktreeSectionsMapper`, `AISessionSectionsMapper`). Formatting goes through
`DevHubUI/Formatters/`.

## 8. Views: `Features/Devices/Views/`

One view per file: `DevicesView.swift` (screen), `DevicesToolbar.swift`, `DeviceRow.swift`. The screen reads its
store, `ProjectSession` and `AppActions`, builds the models and passes closures to the rows.

```swift
struct DevicesView: View {
    @Environment(ProjectSession.self) private var session
    @Environment(DevicesStore.self) private var devices
    @Environment(\.panelOpenCount) private var openCount

    @State private var confirmingID: Device.ID?

    var body: some View {
        VStack(spacing: 0) {
            DevicesToolbar(count: visible.count)
            Divider()
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Theme.surface)
        .animation(.snappy(duration: 0.18), value: confirmingID)
        .task(id: openCount) {
            await devices.refresh()
        }
    }

    private var visible: [Device] {
        devices.devices.filter { session.matchesSearch($0.name) }
    }

    private var content: some View {
        ListState(
            failure: devices.error.map { ListMessage.failure("Cannot read devices", description: $0) { Task { await devices.refresh() } } },
            isLoading: devices.devices.isEmpty && devices.isLoading,
            loadingTitle: "Reading devices…",
            empty: nil,
            noResultsFor: visible.isEmpty ? session.searchText : nil
        ) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(visible.map { DeviceRowMapper.model(for: $0, isBusy: devices.busyIDs.contains($0.id)) }) { model in
                        DeviceRow(model: model, isConfirming: confirmingID == model.id, …)
                        Divider()
                            .padding(.leading, 56)
                    }
                }
            }
        }
    }
}

#Preview {
    DevicesView()
        .previewEnvironment()
}
```

- `.task(id: openCount)` refreshes the tab every time the panel opens. `RootView` sets `\.panelOpenCount`.
- A row takes a model and closures. It reads `Toaster` and `AppActions` at most. It uses `RowContainer` for hover,
  `IconButton` and `OverflowMenu` for actions, the same actions in `.contextMenu`, and `InlineConfirmation` for a
  destructive action. See `ui-components` and `WorktreeRow` for a full row.
- An action that changes another tab is a method on `AppActions` (`appActions.buildAndRun(worktreeID:)`).
- `.devhub` actions in the rows: a new `Placement` constant and `ConfigActionMenuItems` in the row menu. See
  `extensions`.
- Every row file ends with `#Preview { DeviceRow(model: .preview, …) }`.

## 9. Register the tab: `DevHubPresentation/Shell/`

- `FeatureID.swift`: `case devices`, at the position of the tab.
- `FeatureRegistry.swift`: one line in `all`, at the same position. `FeatureRegistryTests` checks that
  `FeatureRegistry.all` and `FeatureID.allCases` have the same order.

```swift
Feature(id: .devices, title: "Devices", systemImage: "ipad.and.iphone", searchPrompt: "Search devices") { DevicesView() },
```

- The tab bar (⌘1 to ⌘9 for the first nine tabs), the header search prompt and the ⌘K palette read
  `FeatureRegistry` through `TabItemMapper`. Nothing else to add.
- `showsInTabBar: false` hides a tab from the bar (Settings uses it). `searchPrompt: nil` hides the search field.
- Open the tab from code with `navigator.show(.devices)`. The selection is a `TabID` (`.feature(FeatureID)` or
  `.custom(String)` for a `.devhub` tab) and is saved under `navigator.selection`.
- Debug: `DEVHUB_OPEN_PANEL=1 DEVHUB_TAB=devices` opens the panel on the new tab (`build-and-run`).

## 10. Tests

| Suite | Target and folder |
|---|---|
| `DeviceListParserTests` | `DevHubDataTests/<Area>/`, fixture in `Fixtures/` |
| `<Verb>DeviceUseCaseTests` (when there is a use case) | `DevHubDomainTests/UseCases/`, over `Ports.spies()` |
| `DeviceRowMapperTests` | `DevHubPresentationTests/Mappers/Devices/` |
| `DevicesStoreTests` | `DevHubPresentationTests/Stores/Devices/`, over `StoreHarness` |
| `ModelPreviewsTests` | one `#expect` that `DeviceRowModel.preview` builds |

```swift
@Suite struct DevicesStoreTests {
    private let harness = StoreHarness()

    @Test func refreshLoadsTheDevices() async {
        harness.spies.devices.listResult = DeviceSample.all

        await harness.devices.refresh()

        #expect(harness.devices.devices == DeviceSample.all)
        #expect(harness.spies.devices.calls == [.list])
    }
}
```

## 11. Build, look, document

```sh
Scripts/build.sh
Scripts/test.sh
DEVHUB_OPEN_PANEL=1 DEVHUB_TAB=devices DEVHUB_SNAPSHOT=/tmp/devices.png "$(Scripts/build.sh | tail -1)/Contents/MacOS/DevHub"
```

`layers: ok`, `anonymous: ok`, the app path and one passing test line. Read the snapshot. Then load `update-docs`.

## Checklist

- [ ] Model, port and error in Domain with `package` access and an explicit `package init`
- [ ] Live repository, parser, mock, `MockData+<Area>`, spy
- [ ] One line each in `Ports`, `Ports.live`, `Ports.mock`, `PortSpies`, `Ports.spies`
- [ ] Store with `RefreshTask`, failures in `ActivityLog`, no other feature's store
- [ ] `PresentationAssembly`, `View+Inject`, `StoreHarness`, preview state if needed
- [ ] Row model with `static let preview`, pure mapper, one view per file, `#Preview` in each
- [ ] Row actions on hover without a layout change, the same actions in `.contextMenu`, hints on icon buttons
- [ ] `FeatureID` case and `FeatureRegistry.all` line in the same order
- [ ] Parser, mapper, store (and use case) tests; `Scripts/build.sh` and `Scripts/test.sh` clean
- [ ] Snapshot checked; `CHANGELOG.md`, `docs/STATUS.md` screens table, the ADR step log updated
