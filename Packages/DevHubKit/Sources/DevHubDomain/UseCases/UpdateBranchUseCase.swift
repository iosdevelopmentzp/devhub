import Foundation

package struct UpdateBranchUseCase: Sendable {
    package enum Plan: Hashable, Sendable {
        case pullHere
        case pullInWorktree(path: String)
        case fastForward(remote: String)
    }

    package let git: any GitRepository

    package static func plan(branch: GitBranch, currentBranch: String?) -> Plan {
        if branch.name == currentBranch {
            return .pullHere
        }
        if let worktree = branch.worktreePath {
            return .pullInWorktree(path: worktree)
        }
        return .fastForward(remote: branch.upstream.map { BranchName($0).local } ?? branch.name)
    }

    package func execute(_ plan: Plan, branch: GitBranch, checkoutPath: String) async throws {
        switch plan {
        case .pullHere:
            try await git.perform(.pullFastForward, in: checkoutPath)
        case .pullInWorktree(let path):
            try await git.perform(.pullFastForward, in: path)
        case .fastForward(let remote):
            try await git.perform(.fetchBranch(remote: remote, local: branch.name), in: checkoutPath)
        }
    }
}
