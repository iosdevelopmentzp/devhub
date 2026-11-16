import DevHubDomain
import Foundation
import Testing
@testable import DevHubData

@Suite(.tags(.integration)) struct ShellGitChangesRepositoryHiddenIntegrationTests {
    private let repo: TemporaryGitRepository
    private let repository: ShellGitChangesRepository

    init() async throws {
        repo = try await TemporaryGitRepository()
        repository = ShellGitChangesRepository(shell: repo.shell)
    }

    @Test func listsHiddenFilesWithTheirStateAndShowsTheHiddenDiff() async throws {
        try await repo.git("update-index", "--skip-worktree", "--", "README.md")
        try repo.write("hello\nmore\nlocal\n", to: "README.md")

        let files = try await repository.hiddenFiles(in: repo.path)
        let changes = try await repository.changes(in: repo.path)
        let diff = try await repository.hiddenDiff(for: try #require(files.first), in: repo.path)

        #expect(files == [GitHiddenFile(path: "README.md", flags: [.skipWorktree], state: .modified)])
        #expect(changes.isEmpty)
        #expect(diff.lines.contains("+local"))
        #expect(diff.lines.contains("--- a/README.md"))
    }

    @Test func anUntouchedAndADeletedFileHaveTheirState() async throws {
        try await repo.git("update-index", "--assume-unchanged", "--", "README.md")
        let unchanged = try await repository.hiddenFiles(in: repo.path)
        try FileManager.default.removeItem(atPath: (repo.path as NSString).appendingPathComponent("README.md"))

        let deleted = try await repository.hiddenFiles(in: repo.path)
        let diff = try await repository.hiddenDiff(for: try #require(deleted.first), in: repo.path)

        #expect(unchanged == [GitHiddenFile(path: "README.md", flags: [.assumeUnchanged], state: .unchanged)])
        #expect(deleted == [GitHiddenFile(path: "README.md", flags: [.assumeUnchanged], state: .deleted)])
        #expect(diff.lines.contains("-hello"))
    }
}
