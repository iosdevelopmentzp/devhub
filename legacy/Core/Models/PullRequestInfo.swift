import Foundation

nonisolated struct PullRequestInfo: Hashable, Sendable {
    enum State: String, Hashable, Sendable {
        case open
        case draft
        case merged
        case closed
    }

    enum Checks: Hashable, Sendable {
        case none
        case passing
        case failing
        case pending
    }

    var number: Int
    var state: State
    var url: String
    var hasConflicts: Bool
    var review: String?
    var checks: Checks
    var isMergeRequest: Bool

    var label: String {
        (isMergeRequest ? "!" : "#") + String(number)
    }
}

nonisolated enum PullRequestLoad: Hashable, Sendable {
    case notInstalled(command: String)
    case notLoggedIn(command: String)
    case none
    case found(PullRequestInfo)
    case failed(String)
}
