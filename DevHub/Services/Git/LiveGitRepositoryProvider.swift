import Foundation

nonisolated struct LiveGitRepositoryProvider: GitRepositoryProviding {
    let shell: ShellRunner

    private var git: GitShell { GitShell(shell: shell) }

    func summary(at path: String) async -> GitSummary {
        guard let result = try? await shell.run("git", ["status", "--porcelain=v1", "--branch"], cwd: path) else {
            return .notARepository
        }
        guard result.exitCode == 0 else { return .notARepository }
        return GitStatusParser.parse(result.stdout)
    }

    func remoteURL(at path: String) async -> String? {
        guard let result = try? await shell.run("git", ["remote", "get-url", "origin"], cwd: path), result.exitCode == 0 else {
            return nil
        }
        let url = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        return url.isEmpty ? nil : url
    }

    func status(at path: String) async throws -> GitStatus {
        try await git.status(at: path)
    }

    func branches(at path: String, base: String) async throws -> BranchSnapshot {
        try await git.branches(at: path, base: base)
    }

    func history(at path: String, limit: Int) async throws -> [GitCommit] {
        try await git.history(at: path, limit: limit)
    }

    func details(at path: String, base: String) async -> CheckoutDetails {
        await git.details(at: path, base: base)
    }

    func diff(at path: String, change: GitChange, group: GitChange.Group) async throws -> GitDiff {
        try await git.diff(at: path, change: change, group: group)
    }

    func run(_ command: GitCommand, at path: String) async throws -> ShellResult {
        try await git.run(command.arguments, at: path, environment: command.environment)
    }
}
