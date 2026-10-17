import DevHubDomain
import DevHubTestSupport
import Foundation
import Testing
@testable import DevHubData

@Suite(.tags(.integration)) struct ShellGitRepositoryIntegrationTests {
    private let repo: TemporaryGitRepository
    private let repository: ShellGitRepository

    init() async throws {
        repo = try await TemporaryGitRepository()
        repository = ShellGitRepository(shell: repo.shell, worktrees: ShellWorktreeRepository(shell: repo.shell))
    }

    @Test func stateReadsBranchHeadBranchesAndHistory() async throws {
        let head = try await repo.git("rev-parse", "HEAD")

        let state = try await repository.state(checkoutPath: repo.path, mainPath: repo.path, settings: .standard)

        #expect(state.snapshot.branch == "main")
        #expect(state.snapshot.head == String(head.prefix(9)))
        #expect(state.snapshot.upstream == nil)
        #expect(state.snapshot.baseBranch == "origin/main")
        #expect(state.snapshot.changedFiles == 0)
        #expect(state.snapshot.stashCount == 0)
        #expect(state.snapshot.operation == nil)
        #expect(state.snapshot.webURL == nil)
        #expect(Set(state.localBranches.map(\.name)) == ["main", "feature", "merged-branch", "linked"])
        #expect(state.localBranches.first { $0.name == "main" }?.worktreePath == repo.path)
        #expect(state.localBranches.first { $0.name == "linked" }?.worktreePath == repo.linkedPath)
        #expect(state.localBranches.first { $0.name == "feature" }?.subject == "Add feature")
        #expect(state.remoteBranches.isEmpty)
        #expect(state.history.map(\.subject) == ["Second commit", "Initial commit"])
        #expect(state.history.allSatisfy { $0.isPushed == false })
        #expect(state.history.first?.author == "DevHub Tests")
    }

    @Test func stateOfALinkedWorktree() async throws {
        let state = try await repository.state(checkoutPath: repo.linkedPath, mainPath: repo.path, settings: .standard)

        #expect(state.snapshot.branch == "linked")
        #expect(state.history.first?.subject == "Second commit")
    }

    @Test func stateCountsChangedFilesAndStashes() async throws {
        try repo.write("stashed\n", to: "README.md")
        try await repo.git("stash", "push", "-q", "-m", "half done")
        try repo.write("new\n", to: "new.txt")
        try repo.write("changed\n", to: "feature-free.txt")

        let state = try await repository.state(checkoutPath: repo.path, mainPath: repo.path, settings: .standard)

        #expect(state.snapshot.changedFiles == 2)
        #expect(state.snapshot.stashCount == 1)
        #expect(state.stashes.map(\.index) == [0])
        #expect(state.stashes.first?.message == "half done")
        #expect(state.stashes.first?.date != nil)
    }

    @Test func commitSubjectsListTheCommitsOfTheBranchNewestFirst() async throws {
        try await repo.git("switch", "-q", "feature")
        try repo.write("more\n", to: "feature.txt")
        try await repo.commitAll("Polish feature")

        let subjects = try await repository.commitSubjects(from: "main", to: "feature", in: repo.path)

        #expect(subjects == ["Polish feature", "Add feature"])
    }

    @Test func theMergeRequestTemplateIsReadFromTheCheckout() async throws {
        #expect(await repository.mergeRequestTemplate(in: repo.path) == nil)

        try repo.write("## What\n", to: ".gitlab/merge_request_templates/Default.md")

        #expect(await repository.mergeRequestTemplate(in: repo.path) == "## What\n")
    }

    @Test func stateReportsAMergeInProgress() async throws {
        try await repo.git("switch", "-q", "-c", "conflict")
        try repo.write("theirs\n", to: "README.md")
        try await repo.commitAll("Conflict side")
        try await repo.git("switch", "-q", "main")
        try repo.write("ours\n", to: "README.md")
        try await repo.commitAll("Main side")
        let merge = try await repo.shell.run("git", ["merge", "conflict"], cwd: repo.path, environment: [:])

        let state = try await repository.state(checkoutPath: repo.path, mainPath: repo.path, settings: .standard)

        #expect(merge.exitCode != 0)
        #expect(state.snapshot.operation == "merge")
    }

    @Test func webURLComesFromTheOriginRemote() async throws {
        #expect(await repository.webURL(checkoutPath: repo.path, remote: "origin") == nil)

        try await repo.git("remote", "add", "origin", "git@gitlab.com:group/app.git")

        #expect(await repository.webURL(checkoutPath: repo.path, remote: "origin") == URL(string: "https://gitlab.com/group/app"))
        let state = try await repository.state(checkoutPath: repo.path, mainPath: repo.path, settings: .standard)
        #expect(state.snapshot.webURL == URL(string: "https://gitlab.com/group/app"))
    }

    @Test func webURLAndStateUseTheConfiguredRemote() async throws {
        try await repo.git("remote", "add", "upstream", "https://github.com/example/app.git")
        var settings = GitSettings.standard
        settings.remote = "upstream"

        #expect(await repository.webURL(checkoutPath: repo.path, remote: "upstream") == URL(string: "https://github.com/example/app"))
        let state = try await repository.state(checkoutPath: repo.path, mainPath: repo.path, settings: settings)
        #expect(state.snapshot.webURL == URL(string: "https://github.com/example/app"))
        #expect(state.snapshot.baseBranch == "upstream/main")
    }

    @Test func performRunsTheEncodedCommand() async throws {
        try repo.write("new\n", to: "new.txt")

        try await repository.perform(.stageAll, in: repo.path)
        let staged = try await repo.git("diff", "--cached", "--name-only")
        try await repository.perform(.commit(message: "Add new", amend: false), in: repo.path)
        let subject = try await repo.git("log", "-1", "--format=%s")

        #expect(staged == "new.txt\n")
        #expect(subject == "Add new\n")
    }

    @Test func performThrowsCommandErrorOnFailure() async throws {
        let error = await #expect(throws: WorktreeError.self) {
            try await repository.perform(.switchBranch("missing-branch"), in: repo.path)
        }
        guard case .command(let message)? = error else {
            Issue.record("Expected .command, got \(String(describing: error))")
            return
        }
        #expect(message.contains("missing-branch"))
    }
}
