import Foundation

struct OperationRecord: Identifiable, Hashable {
    enum Status: Hashable {
        case running
        case succeeded
        case failed(String)
        case cancelled
    }

    let id: UUID
    let title: String
    let origin: OperationOrigin
    let startedAt: Date
    var finishedAt: Date?
    var status: Status
    var progressText: String?
    var fraction: Double?
    var canRetry: Bool
    var canStop: Bool
    var isDismissed: Bool
    var isSeen: Bool
    var isOutputOpen: Bool

    var isRunning: Bool {
        status == .running
    }

    var failureMessage: String? {
        guard case let .failed(message) = status else { return nil }
        return message
    }
}
