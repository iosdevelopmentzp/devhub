---
name: add-feature
description: "Add a new screen (tab) to DevHub end to end: model types in Core, a provider protocol with mock and live implementations, a feature store, one file per view with rows and hover actions, the FeatureRegistry entry, build check. Use for any 'add a screen / tab / feature / section' request."
---

# Add Feature

A feature is one screen inside the panel. Seven steps, in this order. Load `ui-components` for the building blocks and `providers-and-shell` for the data layer.

## 1. Model — `DevHub/Core/Models/<Name>.swift`

Plain value type. `Identifiable`, `Hashable`, `Sendable`, `let id: String`, everything else `var`. Status is an enum, not a set of Bools. Tints are `Tint` enum values from Core, never `Color`.

```swift
nonisolated struct Device: Identifiable, Hashable, Sendable {
    enum State: Hashable, Sendable {
        case connected
        case disconnected
    }

    let id: String
    var name: String
    var state: State
    var lastSeen: Date
}
```

## 2. Parser — `DevHub/Core/Parsers/<Name>Parser.swift` (when the data comes from a command)

A pure `nonisolated enum` with `static func parse(_ output: String) -> [Device]`. Check it once against the real command output in the Output panel; no test file.

## 3. Provider — `DevHub/Services/<Area>/<Name>Provider.swift`

Protocols and their `Mock…` and `Live…` types are `nonisolated` (default isolation is `MainActor`). A protocol without a live type yet uses its `Mock…` in `Providers.live` (now only build); the view then shows `SampleDataBanner()` on top. Other providers: `hosting` (`PullRequestProviding`), `usage` (`UsageProviding`) and the `AISessionIndex` actor behind `AISessionProviding`.

```swift
protocol DeviceProviding {
    func list() async throws -> [Device]
    func reconnect(id: String) async throws
}

struct MockDeviceProvider: DeviceProviding { ... }   // returns MockData.devices, sleeps a little on actions
struct LiveDeviceProvider: DeviceProviding { ... }   // runs commands through ShellRunner, parses with the parser
```

Add a field to `Providers` and set it in `Providers.mock` and `Providers.live`.

## 4. Store — `DevHub/Features/Devices/DevicesStore.swift`

```swift
import Observation

@MainActor
@Observable
final class DevicesStore {
    var devices: [Device] = []
    private(set) var isLoading = false
    private(set) var error: String?
    private(set) var busyIDs: Set<Device.ID> = []

    @ObservationIgnored private let provider: DeviceProviding
    @ObservationIgnored private let activity: ActivityLog

    init(provider: DeviceProviding, activity: ActivityLog, events: AppEvents) {
        self.provider = provider
        self.activity = activity
        events.subscribe { [weak self] event in
            guard let self else { return }
            guard case .projectChanged = event else { return }
            Task { await refresh() }
        }
    }

    func refresh() async {
        guard isLoading == false else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            devices = try await provider.list()
            error = nil
        } catch {
            self.error = error.localizedDescription
            activity.log("Device list failed", detail: error.localizedDescription, outcome: .failure)
        }
    }
}
```

Wire it in `DevHub/App/AppDependencies.swift`: a `let devices: DevicesStore`, its line in `init` (pass only the stores it reads), `.environment(dependencies.devices)` in `inject(_:)`. Mock data comes from the `Mock…` provider in `Providers.mock`. `AppEvents` lives in `Shared`.

Rules:
- A store depends only on `Shared` types and lower stores. Never on a store that depends on it.
- Something other features show changed: post an `AppEvent`. Something other features changed that this one shows: `subscribe`.
- A button with a spinner keeps a `Set` of running IDs in the store.
- Anything the user would want to see later calls `activity.log(_:detail:outcome:)`.

## 5. Views — `DevHub/Features/Devices/`

One view per file: `DevicesView.swift` (screen), `DevicesToolbar.swift`, `DeviceRow.swift`, panels as needed.

```swift
struct DevicesView: View {
    @Environment(ProjectSession.self) private var session
    @Environment(DevicesStore.self) private var store

    private var devices: [Device] {
        store.devices.filter { session.matchesSearch($0.name) }
    }

    var body: some View {
        VStack(spacing: 0) {
            DevicesToolbar()
            Divider()
            if let error = store.error {
                InlineError(text: error) { Task { await store.refresh() } }
            } else if devices.isEmpty {
                ContentUnavailableView.search(text: session.searchText)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(devices) { device in
                            DeviceRow(device: device)
                            if device.id != devices.last?.id {
                                Divider().padding(.leading, 56)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .background(Theme.surface)
        .task { await store.refresh() }
    }
}

#Preview {
    DevicesView()
        .previewEnvironment()
}
```

The row follows the row pattern in `ui-components`. An action that crosses features is wired in the view, not in the store.

## 6. Register — `DevHub/Shell/FeatureRegistry.swift`

One line in `FeatureRegistry.all` (the registry lives in `Shell` because it holds views; `Core` stays Foundation only). Position in the array is the tab order. The built-in tabs `home git worktrees simulators logs ai settings` already exist as files with a store and a view; fill them in instead of adding new ones.

```swift
Feature(id: "devices", title: "Devices", systemImage: "ipad.and.iphone", searchPrompt: "Search devices") { AnyView(DevicesView()) },
```

Every tab is a `Feature`. Open one from code with `navigator.show("devices")`. Config placements for the new screen: add a `Placement` case, and render actions with placement `<id>.<slot>` through `ActionCatalog`.

## 7. Build, run, document

```sh
Scripts/build.sh
Scripts/run.sh
```

Zero errors, zero warnings. Then load `update-docs`.

## Checklist

- [ ] Model is a value type in Core with an enum for status
- [ ] Parser is pure and was checked against real output
- [ ] Provider protocol with mock and live, added to `Providers`
- [ ] All mutations live in the feature store, wired in `AppDependencies`
- [ ] One view per file in `Features/<Name>/`
- [ ] Screen filters by `session.matchesSearch`, shows search-empty and error states
- [ ] Row actions appear on hover with `opacity`, no layout jump, same actions in the context menu
- [ ] `#Preview` with `.previewEnvironment()`
- [ ] One line in `FeatureRegistry.all`
- [ ] `Scripts/build.sh` clean, the screen checked in a run
- [ ] `CHANGELOG.md`, `docs/STATUS.md`, `AGENTS.md` layout table updated
