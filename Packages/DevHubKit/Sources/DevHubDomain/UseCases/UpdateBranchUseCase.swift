import Foundation

package struct UpdateBranchUseCase: Sendable {
    package enum Plan: Hashable, Sendable {
        case pullHere
        case pullInWorktree(path: String)
        case fastForward(remote: String)
    }

    package let git: any GitRepository

    package static func plan(branch: GitBranch, currentBranch: String?, remote: String) -> Plan {
        if branch.name == currentBranch {
            return .pullHere
        }
        if let worktree = branch.worktreePath {
            return .pullInWorktree(path: worktree)
        }
        return .fastForward(remote: branch.upstream.map { BranchName($0, remote: remote).local } ?? branch.name)
    }

    package func execute(_ plan: Plan, branch: GitBranch, remote: String, checkoutPath: String) async throws {
        switch plan {
        case .pullHere:
            try await git.perform(.pullFastForward, in: checkoutPath)
        case .pullInWorktree(let path):
            try await git.perform(.pullFastForward, in: path)
        case .fastForward(let source):
            try await git.perform(.fetchBranch(source: source, local: branch.name, remote: remote), in: checkoutPath)
        }
    }
}
