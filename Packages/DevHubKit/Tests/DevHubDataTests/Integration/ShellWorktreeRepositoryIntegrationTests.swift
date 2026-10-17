import DevHubDomain
import Foundation
import Testing
@testable import DevHubData

@Suite(.tags(.integration)) struct ShellWorktreeRepositoryIntegrationTests {
    private let repo: TemporaryGitRepository
    private let repository: ShellWorktreeRepository

    init() async throws {
        repo = try await TemporaryGitRepository()
        repository = ShellWorktreeRepository(shell: repo.shell)
    }

    @Test func listsTheMainAndTheLinkedWorktree() async throws {
        let worktrees = try await repository.list(projectPath: repo.path)

        #expect(worktrees.map(\.path) == [repo.path, repo.linkedPath])
        #expect(worktrees.map(\.kind) == [.main, .linked])
        #expect(worktrees.map(\.branch) == ["main", "linked"])
        #expect(worktrees.allSatisfy { $0.head.count == 9 && $0.isMissing == false && $0.isLocked == false })
        #expect(worktrees.allSatisfy { $0.lastCommit == "Second commit" && $0.lastActivity != nil })
        #expect(worktrees.allSatisfy { $0.upstream == nil && $0.isMerged == false && $0.needsBootstrap == false })
    }

    @Test func countsChangedFilesPerWorktree() async throws {
        try repo.write("dirty\n", at: (repo.linkedPath as NSString).appendingPathComponent("dirty.txt"))

        let worktrees = try await repository.list(projectPath: repo.path)

        #expect(worktrees.map(\.changedFiles) == [0, 1])
    }

    @Test func listOutsideARepositoryThrows() async throws {
        let outside = (repo.root as NSString).appendingPathComponent("outside")
        try FileManager.default.createDirectory(atPath: outside, withIntermediateDirectories: true)

        await #expect(throws: WorktreeError.self) {
            try await repository.list(projectPath: outside)
        }
    }

    @Test func baseBranchFallsBackWithoutARemote() async {
        #expect(await repository.baseBranch(projectPath: repo.path) == "origin/main")
    }

    @Test func createsAWorktreeForANewBranchNextToTheProject() async throws {
        let created = try await repository.create(branch: "topic/new", base: "main", projectPath: repo.path)

        #expect(created.branch == "topic/new")
        #expect(created.path == (repo.root as NSString).appendingPathComponent("repo-topic-new"))
        #expect(repo.exists(created.path))
        let worktrees = try await repository.list(projectPath: repo.path)
        #expect(worktrees.map(\.branch).contains("topic/new"))
    }

    @Test func createsAWorktreeForAnExistingBranch() async throws {
        let created = try await repository.create(branch: "feature", base: "main", projectPath: repo.path)

        #expect(repo.exists((created.path as NSString).appendingPathComponent("feature.txt")))
    }

    @Test func createsAgentWorktreesUnderTheClaudeFolderAndCopiesIncludedFiles() async throws {
        try FileManager.default.createDirectory(atPath: (repo.path as NSString).appendingPathComponent(".claude/worktrees"), withIntermediateDirectories: true)
        try repo.write("Secrets.xcconfig\n# comment\n*.local\nConfig/Keys.plist\n", to: ".worktreeinclude")
        try repo.write("KEY = 1\n", to: "Secrets.xcconfig")
        try repo.write("<plist/>\n", to: "Config/Keys.plist")

        let created = try await repository.create(branch: "agent-task", base: "main", projectPath: repo.path)

        #expect(created.path == (repo.path as NSString).appendingPathComponent(".claude/worktrees/agent-task"))
        #expect(repo.exists((created.path as NSString).appendingPathComponent("Secrets.xcconfig")))
        #expect(repo.exists((created.path as NSString).appendingPathComponent("Config/Keys.plist")))
        let worktrees = try await repository.list(projectPath: repo.path)
        #expect(worktrees.first { $0.branch == "agent-task" }?.kind == .agent)
    }

    @Test func invalidBranchNameThrows() async throws {
        let error = await #expect(throws: WorktreeError.self) {
            try await repository.create(branch: "bad..name", base: "main", projectPath: repo.path)
        }
        guard case .invalidBranchName? = error else {
            Issue.record("Expected .invalidBranchName, got \(String(describing: error))")
            return
        }
    }

    @Test func removesADirtyWorktree() async throws {
        try repo.write("dirty\n", at: (repo.linkedPath as NSString).appendingPathComponent("dirty.txt"))
        let linked = try #require(try await repository.list(projectPath: repo.path).last)

        try await repository.remove(linked, projectPath: repo.path)

        #expect(try await repository.list(projectPath: repo.path).count == 1)
        #expect(repo.exists(repo.linkedPath) == false)
    }

    @Test func prunesAMissingWorktree() async throws {
        try FileManager.default.removeItem(atPath: repo.linkedPath)
        let before = try await repository.list(projectPath: repo.path)

        try await repository.prune(projectPath: repo.path)

        #expect(before.last?.isMissing == true)
        #expect(try await repository.list(projectPath: repo.path).count == 1)
    }

    @Test func deletesOnlyMergedBranches() async throws {
        try await repository.deleteBranch("merged-branch", projectPath: repo.path)

        #expect(try await repo.git("branch", "--list", "merged-branch").isEmpty)
        await #expect(throws: WorktreeError.self) {
            try await repository.deleteBranch("feature", projectPath: repo.path)
        }
    }

    @Test func fetchWithoutARemoteThrows() async {
        await #expect(throws: WorktreeError.self) {
            try await repository.fetch(projectPath: repo.path)
        }
    }

    @Test func bootstrapStreamsTheInitScript() async throws {
        try repo.write("echo boot\necho done\n", at: (repo.linkedPath as NSString).appendingPathComponent("init.sh"))
        let lines = LineBox()

        try await repository.bootstrap(worktreePath: repo.linkedPath) { lines.append($0) }

        #expect(lines.values == ["boot", "done"])
    }

    @Test func failingBootstrapThrows() async throws {
        try repo.write("exit 3\n", at: (repo.linkedPath as NSString).appendingPathComponent("init.sh"))

        let error = await #expect(throws: WorktreeError.self) {
            try await repository.bootstrap(worktreePath: repo.linkedPath) { _ in }
        }
        guard case .command(let message)? = error else {
            Issue.record("Expected .command, got \(String(describing: error))")
            return
        }
        #expect(message == "init.sh exited with code 3.")
    }
}

private final class LineBox: @unchecked Sendable {
    private let lock = NSLock()
    private var lines: [String] = []

    var values: [String] {
        lock.withLock { lines }
    }

    func append(_ line: String) {
        lock.withLock { lines.append(line) }
    }
}
