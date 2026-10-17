import Foundation

package enum WorktreeCleanupPolicy {

    package static func isSafeToClean(_ worktree: Worktree) -> Bool {
        worktree.isMain == false
            && worktree.isFinished
            && worktree.isDirty == false
            && worktree.isLocked == false
            && worktree.isMissing == false
    }

    package static func finished(in worktrees: [Worktree], excluding path: String?) -> [Worktree] {
        worktrees.filter { isSafeToClean($0) && $0.path != path }
    }

    package static func deleteWarnings(for worktree: Worktree) -> [String] {
        var result: [String] = []
        if worktree.isDirty {
            result.append("\(worktree.changedFiles) uncommitted changes will be lost (git worktree remove --force).")
        }
        if worktree.upstream == nil, worktree.isFinished == false, worktree.branch != nil {
            result.append("The branch was never pushed. Keep the branch to keep its commits.")
        } else if worktree.ahead > 0 {
            result.append("\(worktree.ahead) commits are not pushed. Keep the branch to keep them.")
        }
        if worktree.isLocked {
            result.append("The worktree is locked.")
        }
        return result
    }

    package static func defaultDeleteBranch(for worktree: Worktree) -> Bool {
        worktree.isFinished
    }
}
