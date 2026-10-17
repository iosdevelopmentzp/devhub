import Foundation

package enum BranchCleanupPolicy {
    package static func isFinished(_ branch: GitBranch) -> Bool {
        branch.isMerged || branch.isGone
    }

    package static func candidates(branches: [GitBranch], currentBranch: String?, baseName: String, protected: [String]) -> [GitBranch] {
        let protectedNames = Set(protected)
        return branches.filter { branch in
            isFinished(branch)
                && branch.name != currentBranch
                && branch.worktreePath == nil
                && branch.name != baseName
                && protectedNames.contains(branch.name) == false
        }
    }

    package static func usesForce(_ branch: GitBranch, forceGone: Bool) -> Bool {
        forceGone && branch.isGone
    }
}
