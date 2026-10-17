import Foundation

package struct DiscardChangeUseCase: Sendable {
    package let changes: any GitRepository

    package func execute(_ change: GitFileChange, checkoutPath: String) async throws {
        try await changes.perform(Self.command(for: change), in: checkoutPath)
    }

    private static func command(for change: GitFileChange) -> GitCommand {
        switch change.area {
        case .untracked:
            return .cleanUntracked(path: change.path)
        case .unstaged, .conflicted:
            return .restore(path: change.path)
        case .staged:
            return .restoreStagedAndWorktree(path: change.path)
        }
    }
}
