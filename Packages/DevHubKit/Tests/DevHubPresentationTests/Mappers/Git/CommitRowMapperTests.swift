import DevHubDomain
import DevHubUI
import Foundation
import Testing
@testable import DevHubPresentation

@Suite struct CommitRowMapperTests {
    private let base = URL(string: "https://gitlab.example.com/org/app")

    @Test func pushedCommitWithoutDate() {
        let model = CommitRowMapper.model(for: GitBranchFixture.commit, webBase: base, hostKind: nil, expansion: nil)

        #expect(model.id == "a1b2c3d4e5f6")
        #expect(model.hash == "a1b2c3d4e5f6")
        #expect(model.shortHash == "a1b2c3d")
        #expect(model.subject == "ABC-1: Login screen")
        #expect(model.tags.isEmpty)
        #expect(model.author == "alex")
        #expect(model.dateText == nil)
        #expect(model.webURL?.absoluteString == "https://gitlab.example.com/org/app/-/commit/a1b2c3d4e5f6")
        #expect(model.files == nil)
        #expect(model.isExpanded == false)
    }

    @Test func unpushedCommitWithDateHasNoWebLink() {
        var commit = GitBranchFixture.commit
        commit.isPushed = false
        commit.date = Date(timeIntervalSinceNow: -3_600)

        let model = CommitRowMapper.model(for: commit, webBase: base, hostKind: nil, expansion: nil)

        #expect(model.tags == [TagModel("not pushed", tint: .orange)])
        #expect(model.dateText?.isEmpty == false)
        #expect(model.webURL == nil)
    }

    @Test func refsAndAMergeGetTags() {
        var commit = GitBranchFixture.commit
        commit.refs = [GitCommitRef(kind: .head, name: "HEAD"), GitCommitRef(kind: .localBranch, name: "main")]
        commit.isMerge = true
        commit.isPushed = false

        let model = CommitRowMapper.model(for: commit, webBase: nil, hostKind: nil, expansion: nil)

        #expect(model.refTags.map(\.text) == ["HEAD", "main"])
        #expect(model.tags.map(\.text) == ["merge", "not pushed"])
    }

    @Test func expandedCommitWaitsForItsFiles() {
        let model = CommitRowMapper.model(for: GitBranchFixture.commit, webBase: nil, hostKind: nil, expansion: expansion(files: nil))

        #expect(model.files == .loading)
        #expect(model.isExpanded)
    }

    @Test func expandedCommitShowsAnErrorOrAnEmptyNote() {
        let failed = CommitRowMapper.model(for: GitBranchFixture.commit, webBase: nil, hostKind: nil, expansion: expansion(files: nil, error: "bad object"))
        let empty = CommitRowMapper.model(for: GitBranchFixture.commit, webBase: nil, hostKind: nil, expansion: expansion(files: []))

        #expect(failed.files == .note("Cannot read the files: bad object"))
        #expect(empty.files == .note("No file changes in this commit"))
    }

    @Test func expandedCommitListsItsFilesWithTheOpenDiff() {
        let open = GitCommitFile(path: "App/Login.swift", originalPath: nil, kind: .modified)
        let closed = GitCommitFile(path: "App/Gift.swift", originalPath: nil, kind: .added)
        let key = CommitFileKey(hash: "a1b2c3d4e5f6", path: open.path)
        let diff = GitDiff(lines: ["@@ -1 +1 @@", "-a", "+b"], droppedLines: 0, isBinary: false)

        let model = CommitRowMapper.model(
            for: GitBranchFixture.commit,
            webBase: nil,
            hostKind: nil,
            expansion: expansion(files: [open, closed], expandedFiles: [key], diffs: [key: diff])
        )

        guard case .loaded(let rows) = model.files else {
            Issue.record("Expected loaded files")
            return
        }
        #expect(rows.map(\.path) == ["App/Login.swift", "App/Gift.swift"])
        #expect(rows[0].isExpanded)
        #expect(rows[0].diff == DiffMapper.model(for: diff))
        #expect(rows[1].isExpanded == false)
    }

    private func expansion(
        files: [GitCommitFile]?,
        error: String? = nil,
        expandedFiles: Set<CommitFileKey> = [],
        diffs: [CommitFileKey: GitDiff] = [:]
    ) -> CommitRowMapper.Expansion {
        CommitRowMapper.Expansion(files: files, error: error, expandedFiles: expandedFiles, diffs: diffs)
    }
}
