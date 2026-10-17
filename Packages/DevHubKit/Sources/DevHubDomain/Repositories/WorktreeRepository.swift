import Foundation

package protocol WorktreeRepository: Sendable {
    func list(projectPath: String, settings: GitSettings) async throws -> [Worktree]
    func baseBranch(projectPath: String, remote: String) async -> String
    func fetch(projectPath: String, remote: String) async throws
    func remove(_ worktree: Worktree, projectPath: String) async throws
    func deleteBranch(_ branch: String, projectPath: String) async throws
    func prune(projectPath: String) async throws
    func create(branch: String, base: String, projectPath: String, settings: GitSettings) async throws -> NewWorktree
    func bootstrap(worktreePath: String, script: String, onLine: @escaping @Sendable (String) -> Void) async throws
}
