---
paths:
  - "Packages/DevHubKit/Sources/DevHubDomain/**"
---

# Domain rules

- `import Foundation` only. No SwiftUI, AppKit, Observation, `Process`, `UserDefaults`, `NSWorkspace`. DevHubDomain
  depends on no other module.
- Nonisolated is the module default: never write `nonisolated` on a type. Every type is `Sendable`. Never
  `MainActor.assumeIsolated`.
- `package` on every type and member another module uses, including nested enums and `static let`. A struct that
  Data, Mocks, Presentation or the tests build gets an explicit `package init` listing its stored properties in
  declaration order; a property with a default value keeps that default in the init.
- A model is a value type: `let id`, `var` fields, an enum for state. No colour, no icon chosen by the app, no
  display string. Data from the user (a title in a script header, an icon name in a JSON file) is data and may stay.

```swift
package struct Simulator: Identifiable, Hashable, Sendable {
    package enum State: Hashable, Sendable { case booted, shutdown, booting, shuttingDown }

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

- A port is a `package protocol … : Sendable`. Requirements carry no access keyword. Methods are `async throws`,
  long work returns `AsyncThrowingStream` or takes an `onEvent` closure. A port never exposes command arguments, exit
  codes or raw output. Intent goes through typed values (`GitCommand`). A new port is a field in `Ports`
  (`Assembly/Ports.swift`).

```swift
package protocol WorktreeRepository: Sendable {
    func list(projectPath: String) async throws -> [Worktree]
    func remove(_ worktree: Worktree, projectPath: String) async throws
}
```

- A policy is pure: inputs in, decision out. No port, no clock, no side effect.

```swift
package enum WorktreeCleanupPolicy {
    package static func isSafeToClean(_ worktree: Worktree) -> Bool
    package static func deleteWarnings(for worktree: Worktree) -> [String]
}
```

- A use case holds ports as `let` properties and has one entry point. It exists only when there is a rule, a
  multi-step sequence or two or more ports. It returns a result or a stream. It never logs, toasts or navigates. A
  new use case is a field and one line in `UseCases(ports:)` (`Assembly/UseCases.swift`). Only `UseCases`
  builds a use case, so its memberwise init can stay internal.

```swift
package struct RemoveWorktreeUseCase: Sendable {
    package let worktrees: any WorktreeRepository
    package let derivedData: any DerivedDataRepository

    package func execute(_ worktree: Worktree, projectPath: String, deleteDerivedData: Bool, deleteBranch: Bool, derivedDataSize: Int64) async -> RemovalSummary
}
```

- Errors: one `LocalizedError` enum per file in `Errors/`. The message tells the user what to do next when there is
  something to do.
- Values (`BranchName`, `ProjectPath`) replace string helpers. No new `extension String` for a domain concept.
- Data that both Data and Mocks need lives here.
- Every policy, value rule and use case has a suite in `Tests/DevHubDomainTests/`; use cases are tested over
  `Ports.spies()`.
