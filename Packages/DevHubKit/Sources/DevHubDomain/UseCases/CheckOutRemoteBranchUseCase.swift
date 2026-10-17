import Foundation

package struct CheckOutRemoteBranchUseCase: Sendable {
    package enum Plan: Hashable, Sendable {
        case switchExisting(local: String)
        case createTracking(local: String, remote: String)
    }

    package let git: any GitRepository

    package static func plan(remote: RemoteBranch, localBranches: [GitBranch]) -> Plan {
        let local = BranchName(remote.name).local
        guard localBranches.contains(where: { $0.name == local }) else {
            return .createTracking(local: local, remote: remote.name)
        }
        return .switchExisting(local: local)
    }

    package func execute(_ plan: Plan, checkoutPath: String) async throws {
        switch plan {
        case .switchExisting(let local):
            try await git.perform(.switchBranch(local), in: checkoutPath)
        case .createTracking(let local, let remote):
            try await git.perform(.createTrackingBranch(local: local, remote: remote), in: checkoutPath)
        }
    }
}
