import Foundation

package enum ActivityTarget: Hashable, Codable, Sendable {
    case pullRequest(iid: Int)
    case reviewQueue
    case worktree(path: String)
    case build
}
