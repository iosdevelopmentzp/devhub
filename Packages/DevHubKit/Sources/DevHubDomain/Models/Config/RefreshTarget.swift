import Foundation

package enum RefreshTarget: String, Codable, Hashable, Sendable {
    case git
    case worktrees
    case simulators
    case scripts
    case logs
    case pullRequests
}
