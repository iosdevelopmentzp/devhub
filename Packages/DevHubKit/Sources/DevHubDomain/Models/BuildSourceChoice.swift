import Foundation

package enum BuildSourceChoice: Codable, Hashable, Sendable {
    case main
    case worktree(String)
    case branch(String)
}
