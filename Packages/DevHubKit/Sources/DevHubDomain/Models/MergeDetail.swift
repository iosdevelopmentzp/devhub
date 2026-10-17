import Foundation

package enum MergeDetail: Hashable, Sendable {
    case mergeable
    case notApproved
    case ciMustPass
    case ciStillRunning
    case discussionsNotResolved
    case needRebase
    case draftStatus
    case other(String)

    package var name: String {
        switch self {
        case .mergeable: "mergeable"
        case .notApproved: "not_approved"
        case .ciMustPass: "ci_must_pass"
        case .ciStillRunning: "ci_still_running"
        case .discussionsNotResolved: "discussions_not_resolved"
        case .needRebase: "need_rebase"
        case .draftStatus: "draft_status"
        case .other(let name): name
        }
    }
}
