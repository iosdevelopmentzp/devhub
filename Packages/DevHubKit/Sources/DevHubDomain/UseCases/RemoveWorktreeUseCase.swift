import Foundation

package struct RemoveWorktreeUseCase: Sendable {
    package struct RemovalSummary: Hashable, Sendable {
        package var title: String
        package var detail: String
        package var outcome: ActivityEvent.Outcome
        package var reclaimedBytes: Int64
    }

    package let worktrees: any WorktreeRepository
    package let derivedData: any DerivedDataRepository

    package func execute(
        _ worktree: Worktree,
        projectPath: String,
        deleteDerivedData: Bool,
        deleteBranch: Bool,
        derivedDataSize: Int64
    ) async -> RemovalSummary {
        let derivedDataFolder = deleteDerivedData ? derivedData.folder(forCheckout: worktree.path) : nil
        do {
            try await worktrees.remove(worktree, projectPath: projectPath)
        } catch {
            return RemovalSummary(
                title: "Could not remove worktree",
                detail: "\(worktree.displayName): \(error.localizedDescription)",
                outcome: .failure,
                reclaimedBytes: 0
            )
        }
        var notes: [String] = []
        var reclaimed: Int64 = 0
        if let derivedDataFolder {
            do {
                try derivedData.remove(derivedDataFolder)
                reclaimed = derivedDataSize
                notes.append("DerivedData \(ByteCountFormatter.string(fromByteCount: derivedDataSize, countStyle: .file)) freed")
            } catch {
                notes.append("DerivedData kept: \(error.localizedDescription)")
            }
        }
        if deleteBranch, let branch = worktree.branch {
            do {
                try await worktrees.deleteBranch(branch, projectPath: projectPath)
                notes.append("branch deleted")
            } catch {
                notes.append("branch kept: not fully merged")
            }
        }
        return RemovalSummary(
            title: "Removed worktree",
            detail: ([worktree.displayName] + notes).joined(separator: " · "),
            outcome: .info,
            reclaimedBytes: reclaimed
        )
    }
}
