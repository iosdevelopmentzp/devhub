import Foundation

nonisolated struct ActionResult: Hashable, Sendable {
    enum Status: Hashable, Sendable {
        case running
        case succeeded
        case failed(String)
        case cancelled
    }

    var status: Status
    var startedAt: Date
    var finishedAt: Date?
    var view: ScriptView?

    var failureMessage: String? {
        guard case let .failed(message) = status else { return nil }
        return message
    }

    var isRunning: Bool { status == .running }
}

nonisolated struct ActionProgress: Hashable, Sendable {
    let actionID: String
    let actionTitle: String
    let text: String
    let fraction: Double?
}

nonisolated struct PendingRun: Hashable, Sendable {
    let action: CatalogAction
    let slot: String
    var item: ActionItemContext
    var inputs: [String: String]
}
