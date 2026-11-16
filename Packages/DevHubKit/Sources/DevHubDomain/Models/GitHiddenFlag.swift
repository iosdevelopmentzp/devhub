import Foundation

package enum GitHiddenFlag: Hashable, Sendable, CaseIterable {
    case skipWorktree
    case assumeUnchanged

    package var name: String {
        switch self {
        case .skipWorktree: "skip-worktree"
        case .assumeUnchanged: "assume-unchanged"
        }
    }
}
