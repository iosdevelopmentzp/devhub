import Foundation

package protocol WorktreeRepository: Sendable {
    func list(projectPath: String) async throws -> [Worktree]
    func baseBranch(projectPath: String) async -> String
    func fetch(projectPath: String) async throws
    func remove(_ worktree: Worktree, projectPath: String) async throws
    func deleteBranch(_ branch: String, projectPath: String) async throws
    func prune(projectPath: String) async throws
    func create(branch: String, base: String, projectPath: String) async throws -> NewWorktree
    func bootstrap(worktreePath: String, onLine: @escaping @Sendable (String) -> Void) async throws
}
