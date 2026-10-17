import Foundation

nonisolated protocol GitRepositoryProviding: Sendable {
    func summary(at path: String) async -> GitSummary
    func remoteURL(at path: String) async -> String?
    func status(at path: String) async throws -> GitStatus
    func branches(at path: String, base: String) async throws -> BranchSnapshot
    func history(at path: String, limit: Int) async throws -> [GitCommit]
    func details(at path: String, base: String) async -> CheckoutDetails
    func diff(at path: String, change: GitChange, group: GitChange.Group) async throws -> GitDiff
    func run(_ command: GitCommand, at path: String) async throws -> ShellResult
}
