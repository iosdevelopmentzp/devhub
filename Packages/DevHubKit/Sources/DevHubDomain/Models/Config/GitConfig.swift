import Foundation

package struct GitConfig: Codable, Hashable, Sendable {
    package var baseBranch: String? = nil
    package var commitPrefix: CommitPrefixConfig? = nil
    package var worktrees: WorktreesConfig? = nil

    package init(
        baseBranch: String? = nil,
        commitPrefix: CommitPrefixConfig? = nil,
        worktrees: WorktreesConfig? = nil
    ) {
        self.baseBranch = baseBranch
        self.commitPrefix = commitPrefix
        self.worktrees = worktrees
    }
}
