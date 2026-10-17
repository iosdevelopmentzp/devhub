import Foundation

package struct UpdateBaseBranchUseCase: Sendable {
    package enum Plan: Hashable, Sendable {
        case updateLocal(GitBranch, UpdateBranchUseCase.Plan)
        case fetchMissing(String)
    }

    package let git: any GitRepository

    package static func plan(baseName: String, localBranches: [GitBranch], currentBranch: String?) -> Plan {
        guard let branch = localBranches.first(where: { $0.name == baseName }) else {
            return .fetchMissing(baseName)
        }
        return .updateLocal(branch, UpdateBranchUseCase.plan(branch: branch, currentBranch: currentBranch))
    }

    package func execute(_ plan: Plan, checkoutPath: String) async throws {
        switch plan {
        case .updateLocal(let branch, let branchPlan):
            try await UpdateBranchUseCase(git: git).execute(branchPlan, branch: branch, checkoutPath: checkoutPath)
        case .fetchMissing(let base):
            try await git.perform(.fetchBranch(remote: base, local: base), in: checkoutPath)
        }
    }
}
