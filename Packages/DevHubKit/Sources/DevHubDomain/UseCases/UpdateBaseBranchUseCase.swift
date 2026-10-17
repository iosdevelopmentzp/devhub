import Foundation

package struct UpdateBaseBranchUseCase: Sendable {
    package enum Plan: Hashable, Sendable {
        case updateLocal(GitBranch, UpdateBranchUseCase.Plan)
        case fetchMissing(String)
    }

    package let git: any GitRepository

    package static func plan(baseName: String, localBranches: [GitBranch], currentBranch: String?, remote: String) -> Plan {
        guard let branch = localBranches.first(where: { $0.name == baseName }) else {
            return .fetchMissing(baseName)
        }
        return .updateLocal(branch, UpdateBranchUseCase.plan(branch: branch, currentBranch: currentBranch, remote: remote))
    }

    package func execute(_ plan: Plan, remote: String, checkoutPath: String) async throws {
        switch plan {
        case .updateLocal(let branch, let branchPlan):
            try await UpdateBranchUseCase(git: git).execute(branchPlan, branch: branch, remote: remote, checkoutPath: checkoutPath)
        case .fetchMissing(let base):
            try await git.perform(.fetchBranch(source: base, local: base, remote: remote), in: checkoutPath)
        }
    }
}
