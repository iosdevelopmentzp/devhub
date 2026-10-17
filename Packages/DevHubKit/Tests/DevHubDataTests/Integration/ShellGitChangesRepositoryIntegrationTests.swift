import DevHubDomain
import Foundation
import Testing
@testable import DevHubData

@Suite(.tags(.integration)) struct ShellGitChangesRepositoryIntegrationTests {
    private let repo: TemporaryGitRepository
    private let repository: ShellGitChangesRepository

    init() async throws {
        repo = try await TemporaryGitRepository()
        repository = ShellGitChangesRepository(shell: repo.shell)
    }

    @Test func cleanCheckoutHasNoChanges() async throws {
        #expect(try await repository.changes(in: repo.path).isEmpty)
    }

    @Test func newFileIsUntracked() async throws {
        try repo.write("hello\n", to: "new.txt")
        try repo.write("deep\n", to: "folder/inner/deep.txt")

        let changes = try await repository.changes(in: repo.path)

        #expect(changes == [
            GitFileChange(path: "folder/inner/deep.txt", originalPath: nil, area: .untracked, kind: .untracked),
            GitFileChange(path: "new.txt", originalPath: nil, area: .untracked, kind: .untracked),
        ])
        let diff = try await repository.diff(for: try #require(changes.last), in: repo.path)
        #expect(diff == GitDiff(lines: ["+hello", "+"], droppedLines: 0, isBinary: false))
    }

    @Test func addedFileIsStaged() async throws {
        try repo.write("hello\n", to: "new.txt")
        try await repo.git("add", "new.txt")

        let changes = try await repository.changes(in: repo.path)

        #expect(changes == [GitFileChange(path: "new.txt", originalPath: nil, area: .staged, kind: .added)])
        let diff = try await repository.diff(for: try #require(changes.first), in: repo.path)
        #expect(diff.lines.first?.hasPrefix("diff --git a/new.txt b/new.txt") == true)
        #expect(diff.lines.contains("+hello"))
        #expect(diff.isBinary == false)
    }

    @Test func editedFileIsUnstaged() async throws {
        try repo.write("hello\nchanged\n", to: "README.md")

        let changes = try await repository.changes(in: repo.path)

        #expect(changes == [GitFileChange(path: "README.md", originalPath: nil, area: .unstaged, kind: .modified)])
        let diff = try await repository.diff(for: try #require(changes.first), in: repo.path)
        #expect(diff.lines.contains("-more"))
        #expect(diff.lines.contains("+changed"))
    }

    @Test func movedFileIsAStagedRename() async throws {
        try await repo.git("mv", "README.md", "DOCS.md")

        let changes = try await repository.changes(in: repo.path)

        #expect(changes == [GitFileChange(path: "DOCS.md", originalPath: "README.md", area: .staged, kind: .renamed)])
    }

    @Test func binaryFileDiffIsMarkedBinary() async throws {
        try Data([0, 1, 2, 0, 255]).write(to: URL(fileURLWithPath: (repo.path as NSString).appendingPathComponent("blob.bin")))
        try await repo.git("add", "blob.bin")

        let changes = try await repository.changes(in: repo.path)
        let diff = try await repository.diff(for: try #require(changes.first), in: repo.path)

        #expect(diff.isBinary)
    }

    @Test func branchCommitsAreTheCommitsMissingInTheBase() async throws {
        try await repo.git("switch", "feature")

        let commits = try await repository.branchCommits(base: "main", in: repo.path)

        #expect(commits.map(\.subject) == ["Add feature"])
        #expect(commits.first?.refs == [GitCommitRef(kind: .head, name: "HEAD"), GitCommitRef(kind: .localBranch, name: "feature")])
        #expect(commits.first?.isMerge == false)
    }

    @Test func reflogListsTheLastMovesOfHead() async throws {
        try await repo.git("switch", "feature")

        let entries = try await repository.reflog(in: repo.path)

        #expect(entries.first?.action == "checkout")
        #expect(entries.first?.message == "moving from main to feature")
        #expect(entries.first?.date != nil)
        #expect(entries.contains { $0.action == "commit" && $0.message == "Second commit" })
    }

    @Test func commitFilesAndTheirDiffComeFromTheCommit() async throws {
        let hash = try await repo.git("rev-parse", "feature").trimmingCharacters(in: .whitespacesAndNewlines)

        let files = try await repository.commitFiles(hash: hash, in: repo.path)

        #expect(files == [GitCommitFile(path: "feature.txt", originalPath: nil, kind: .added)])
        let diff = try await repository.commitDiff(hash: hash, file: try #require(files.first), in: repo.path)
        #expect(diff.lines.contains("+feature"))
        #expect(diff.lines.contains { $0.hasPrefix("diff --git a/feature.txt") })
    }

    @Test func aRenameInACommitKeepsBothPaths() async throws {
        try await repo.git("mv", "README.md", "DOCS.md")
        try await repo.commitAll("Rename the readme")

        let files = try await repository.commitFiles(hash: "HEAD", in: repo.path)

        #expect(files == [GitCommitFile(path: "DOCS.md", originalPath: "README.md", kind: .renamed)])
        let diff = try await repository.commitDiff(hash: "HEAD", file: try #require(files.first), in: repo.path)
        #expect(diff.lines.contains("rename to DOCS.md"))
    }
}
