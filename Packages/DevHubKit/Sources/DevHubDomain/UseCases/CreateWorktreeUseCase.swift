import Foundation

package struct CreateWorktreeUseCase: Sendable {
    package let worktrees: any WorktreeRepository

    package func execute(branch: String, base: String, projectPath: String, settings: GitSettings) async throws -> NewWorktree? {
        let name = BranchName(branch.trimmed).local
        guard name.isEmpty == false else { return nil }
        return try await worktrees.create(branch: name, base: base, projectPath: projectPath, settings: settings)
    }
}
