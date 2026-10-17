import Foundation

enum MergeRequestLocalState: Equatable {
    case current
    case worktree(path: String)
    case local
    case none
}
