import Foundation

package struct CleanFinishedWorktreesUseCase: Sendable {
    package struct Report: Sendable {
        package var summaries: [RemoveWorktreeUseCase.RemovalSummary]
        package var removedCount: Int
        package var failedNames: [String]
        package var derivedDataBytes: Int64
    }

    package let remove: RemoveWorktreeUseCase

    package func execute(
        _ targets: [Worktree],
        projectPath: String,
        derivedDataSizes: [Worktree.ID: Int64],
        onRemoved: @escaping @Sendable (Worktree.ID) async -> Void
    ) async -> Report {
        var result = Report(summaries: [], removedCount: 0, failedNames: [], derivedDataBytes: 0)
        for worktree in targets {
            let size = derivedDataSizes[worktree.id] ?? 0
            result.derivedDataBytes += size
            let summary = await remove.execute(
                worktree,
                projectPath: projectPath,
                deleteDerivedData: true,
                deleteBranch: true,
                derivedDataSize: size
            )
            result.summaries.append(summary)
            if summary.outcome == .failure {
                result.failedNames.append(worktree.displayName)
            }
            await onRemoved(worktree.id)
        }
        result.removedCount = targets.count - result.failedNames.count
        return result
    }
}
