import Foundation

package struct SwitchBranchUseCase: Sendable {
    package enum Plan: Hashable, Sendable {
        case switchOnly
        case stashSwitchPop
    }

    package enum Outcome: Hashable, Sendable {
        case switched
        case switchedWithChanges
        case switchedStashKept
    }

    package let git: any GitRepository

    package static func plan(changedFiles: Int) -> Plan {
        changedFiles > 0 ? .stashSwitchPop : .switchOnly
    }

    package func execute(_ plan: Plan, branch: String, in path: String) async throws -> Outcome {
        guard plan == .stashSwitchPop else {
            try await git.perform(.switchBranch(branch), in: path)
            return .switched
        }
        try await git.perform(.stashPush(message: "DevHub: switch to \(branch)", includeUntracked: true), in: path)
        do {
            try await git.perform(.switchBranch(branch), in: path)
        } catch {
            try? await git.perform(.stashPop(index: nil), in: path)
            throw error
        }
        do {
            try await git.perform(.stashPop(index: nil), in: path)
            return .switchedWithChanges
        } catch {
            return .switchedStashKept
        }
    }
}
