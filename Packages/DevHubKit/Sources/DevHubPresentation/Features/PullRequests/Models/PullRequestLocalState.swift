import Foundation

enum PullRequestLocalState: Equatable {
    case current
    case worktree(path: String)
    case local
    case none
}
