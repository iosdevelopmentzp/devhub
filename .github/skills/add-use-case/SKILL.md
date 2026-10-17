---
name: add-use-case
description: "When and how to add a Domain policy or use case in DevHub, how a store consumes it, how a lookup protocol replaces a dependency on another feature's store, how stores tell each other about changes through AppEvents, wiring in UseCases and PresentationAssembly, and the use case test over spies. Load for any 'move this logic out of the store / view', 'add a rule', 'this action needs two repositories', or 'store X needs data from store Y' request."
---

# Add a Use Case

Rules: `docs/ARCHITECTURE.md` sections 4, 6 and 7, `.claude/rules/domain.md`, `.claude/rules/presentation.md`.
Paths below are relative to `Packages/DevHubKit/Sources/`.

## Decide what it is

| The logic is… | Put it in | Shape |
|---|---|---|
| a pure decision over values (is it merged, is it safe to clean, which scheme, which URL) | `DevHubDomain/Policies/<Name>Policy.swift` | `package enum` with `package static` functions, no port, no clock |
| a sequence over one or more ports (create then bootstrap, uninstall then reset then install) | `DevHubDomain/UseCases/<Verb><Thing>UseCase.swift` | `package struct … : Sendable` holding ports, one `package` entry point |
| one port call plus UI state (boot a simulator, fetch) | the store | call the port directly |
| choosing colour, icon, text for a row | `DevHubPresentation/Features/<Name>/Models/<Row>Mapper.swift` | pure static mapper |
| switching the tab and calling a store | `DevHubPresentation/Shared/AppActions.swift` | one method |

A use case exists only when there is a rule, a multi-step sequence or two or more ports. Do not wrap a single
port call.

## Policy

```swift
package enum SchemeChoicePolicy {
    package static func choose(available: [String], saved: String?, current: String, projectDefault: String) -> String? {
        …
    }
}
```

The store calls it and applies the result. Existing policies: `MergedBranchPolicy`, `WorktreeCleanupPolicy`,
`CleanInstallPolicy`, `BuildSourceResolver`, `SchemeChoicePolicy`, `RepositoryWebLinks`, `TicketPrefix`,
`PushPayloadValidator`, `LogTargetPolicy`.

## Use case

```swift
package struct RemoveWorktreeUseCase: Sendable {
    package struct RemovalSummary: Hashable, Sendable {
        package var title: String
        package var detail: String
        package var outcome: ActivityEvent.Outcome
        package var reclaimedBytes: Int64
    }

    package let worktrees: any WorktreeRepository
    package let derivedData: any DerivedDataRepository

    package func execute(_ worktree: Worktree, projectPath: String, deleteDerivedData: Bool, deleteBranch: Bool, derivedDataSize: Int64) async -> RemovalSummary {
        …
    }
}
```

- Ports as `let` properties, values as parameters. Returns a result, a stream, or throws a Domain error.
- Never logs, toasts, navigates or touches store state. Progress goes through an `onStep` closure the store passes.
- Long work: return `AsyncThrowingStream` built with a `Task` and `continuation.onTermination = { _ in task.cancel() }`
  (see `BuildAndRunUseCase`).
- Nonisolated is the module default: no `nonisolated` keyword. `package` on the type, its entry point and any nested
  result type; the memberwise init can stay internal because only `UseCases` builds it.
- One field and one line in `UseCases(ports:)` (`DevHubDomain/Assembly/UseCases.swift`):

```swift
package let removeWorktree: RemoveWorktreeUseCase

removeWorktree = RemoveWorktreeUseCase(worktrees: ports.worktrees, derivedData: ports.derivedData)
```

## The store consumes it

```swift
@ObservationIgnored private let removeWorktree: RemoveWorktreeUseCase

func delete(id: Worktree.ID, deleteDerivedData: Bool, deleteBranch: Bool) {
    guard let worktree = worktree(atPath: id), worktree.isMain == false else { return }
    busyIDs.insert(id)
    Task { [weak self] in
        guard let self else { return }
        let summary = await removeWorktree.execute(worktree, projectPath: session.selectedProject.path, deleteDerivedData: deleteDerivedData, deleteBranch: deleteBranch, derivedDataSize: derivedDataSizes[id] ?? 0)
        busyIDs.remove(id)
        activity.log(summary.title, detail: summary.detail, outcome: summary.outcome)
        await refresh()
    }
}
```

Pass the use case to the store in `DevHubPresentation/Shared/PresentationAssembly.swift`
(`removeWorktree: useCases.removeWorktree`) and in the tests' `StoreHarness`.

The store keeps the busy state, the activity line, the refresh and the event. For a busy-title sequence use
`ActionRunner.run(title, detail:, onFailure:, completion:, work:)`; it sets `busyTitle` before the task starts.

## Data from another feature: a lookup protocol

A store never holds another feature's concrete store. It reads through a narrow protocol in
`DevHubPresentation/Shared/` that the owning store conforms to:

```swift
@MainActor
protocol SimulatorLookup: AnyObject {
    var all: [Simulator] { get }
    func simulator(id: Simulator.ID) -> Simulator?
}

extension SimulatorsStore: SimulatorLookup {}
```

`BuildStore` takes `simulators: any SimulatorLookup`; `PresentationAssembly` passes the real store. Observation tracking
works through the existential. Existing lookups: `WorktreeLookup`, `SimulatorLookup`, `IdentityLookup`,
`CheckoutContext`.

## Changes in another feature: an event

A store never calls a mutating method on another feature's store. It changes the data through a use case and posts
an `AppEvent`; the owning store subscribes in `init` and refreshes:

```swift
events.post(.worktreeCheckoutPrepared)
```

```swift
subscription = events.subscribe { [weak self] event in
    guard let self else { return }
    switch event {
    case .worktreeCheckoutPrepared:
        Task { await self.refresh() }
    …
    }
}
```

Add a case to `DevHubPresentation/Shared/Events/AppEvent.swift` only when a second store needs to react. Handlers run synchronously in
subscription order. A refresh posts only when the data actually changed, and a store ignores the echo of its own
post (`GitStore.isPostingBranchesChanged`).

## Test it

A use case test lives in `Packages/DevHubKit/Tests/DevHubDomainTests/UseCases/<Name>UseCaseTests.swift` and runs over
spies. Pin the exact port calls and the result for each path, including the failure path.

```swift
import DevHubTestSupport
import Testing
@testable import DevHubDomain

@Suite struct RebaseOnBaseUseCaseTests {
    @Test func failedFetchStopsBeforeTheRebase() async {
        let (ports, spies) = Ports.spies()
        spies.git.performError = TestError.scripted("offline")

        await #expect(throws: TestError.scripted("offline")) {
            try await RebaseOnBaseUseCase(git: ports.git).execute(baseName: "dev", baseRef: "origin/dev", checkoutPath: "/repo")
        }
        #expect(spies.git.calls == [.perform(.fetchRef("dev"), path: "/repo")])
    }
}
```

A policy test is a table of inputs and expected decisions, no spies. The store side (busy state, activity line,
event) is tested in `DevHubPresentationTests/Stores/` with `StoreHarness`. See `/testing`.

## Checklist

- [ ] Policy or use case in DevHubDomain, `package`, `Sendable`, Foundation only, no `nonisolated` keyword
- [ ] No logging, toast, navigation or store state inside it
- [ ] One line in `UseCases(ports:)`; the store receives it in `init` from `PresentationAssembly` and `StoreHarness`
- [ ] Cross-feature reads through a lookup protocol, changes through a use case plus an event
- [ ] A suite in `DevHubDomainTests`, store behaviour in `DevHubPresentationTests`
- [ ] `Scripts/build.sh` (`layers: ok`) and `Scripts/test.sh` clean
