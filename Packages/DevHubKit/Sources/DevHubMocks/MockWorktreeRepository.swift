import Foundation
import DevHubDomain

struct MockWorktreeRepository: WorktreeRepository {

    func list(projectPath: String, settings: GitSettings) async throws -> [Worktree] {
        MockData.worktrees
    }

    func baseBranch(projectPath: String, remote: String) async -> String {
        "\(remote)/main"
    }

    func fetch(projectPath: String, remote: String) async throws {
        try await Task.sleep(for: .milliseconds(800))
    }

    func remove(_ worktree: Worktree, projectPath: String) async throws {
        try await Task.sleep(for: .milliseconds(500))
    }

    func deleteBranch(_ branch: String, projectPath: String) async throws {}

    func prune(projectPath: String) async throws {}

    func create(branch: String, base: String, projectPath: String, settings: GitSettings) async throws -> NewWorktree {
        try await Task.sleep(for: .milliseconds(600))
        return NewWorktree(path: "\(projectPath)/.worktrees/\(branch)", branch: branch)
    }

    func bootstrap(worktreePath: String, script: String, onLine: @escaping @Sendable (String) -> Void) async throws {
        try await Task.sleep(for: .seconds(2))
    }
}
