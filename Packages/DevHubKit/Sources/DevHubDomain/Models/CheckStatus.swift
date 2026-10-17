import Foundation

package enum CheckStatus: Hashable, Sendable {
    case success
    case failed
    case running
    case pending
    case created
    case waitingForResource
    case preparing
    case scheduled
    case canceled
    case skipped
    case manual
    case other(String)

    package var name: String {
        switch self {
        case .success: "success"
        case .failed: "failed"
        case .running: "running"
        case .pending: "pending"
        case .created: "created"
        case .waitingForResource: "waiting_for_resource"
        case .preparing: "preparing"
        case .scheduled: "scheduled"
        case .canceled: "canceled"
        case .skipped: "skipped"
        case .manual: "manual"
        case .other(let name): name
        }
    }
}
