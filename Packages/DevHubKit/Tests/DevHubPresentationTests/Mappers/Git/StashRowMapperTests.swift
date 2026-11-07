import DevHubDomain
import Foundation
import Testing
@testable import DevHubPresentation

@Suite struct StashRowMapperTests {
    @Test func aStashShowsItsReferenceMessageAndBranch() {
        let stash = GitStash(index: 3, hash: "abc123", branch: "feature/login", message: "half done", date: Date(timeIntervalSinceNow: -60))

        let model = StashRowMapper.model(for: stash, isBusy: false)

        #expect(model.id == 3)
        #expect(model.hash == "abc123")
        #expect(model.reference == "stash@{3}")
        #expect(model.branchPlaceholder == "feature/login-stash")
        #expect(model.files == nil)
        #expect(model.isExpanded == false)
        #expect(model.message == "half done")
        #expect(model.branch == "feature/login")
        #expect(model.dateText != nil)
        #expect(model.dropMessage == "Drop stash@{3}? Its changes are lost.")
        #expect(model.areActionsEnabled)
    }

    @Test func anEmptyMessageAndABusyRepository() {
        let model = StashRowMapper.model(for: GitStash(index: 0, hash: "x", branch: nil, message: "", date: nil), isBusy: true)

        #expect(model.message == "No message")
        #expect(model.branch == nil)
        #expect(model.branchPlaceholder == "stash-stash")
        #expect(model.dateText == nil)
        #expect(model.areActionsEnabled == false)
    }

    @Test func anExpandedStashListsItsFilesWithTheirDiffs() {
        let stash = GitStash(index: 1, hash: "abc123", branch: "dev", message: "wip", date: nil)
        let file = GitCommitFile(path: "App/New.swift", originalPath: nil, kind: .untracked)
        let key = CommitFileKey(hash: "abc123", path: "App/New.swift")
        let expansion = CommitRowMapper.Expansion(files: [file], error: nil, expandedFiles: [key], diffs: [key: GitDiff(lines: ["@@ -0,0 +1 @@", "+new"], droppedLines: 0, isBinary: false)])

        let model = StashRowMapper.model(for: stash, isBusy: false, expansion: expansion)

        guard case .loaded(let rows) = model.files else {
            Issue.record("Expected loaded files")
            return
        }
        #expect(model.isExpanded)
        #expect(rows.map(\.id) == [key])
        #expect(rows[0].letter == "?")
        #expect(rows[0].isExpanded)
        #expect(StashRowMapper.model(for: stash, isBusy: false, expansion: CommitRowMapper.Expansion(files: nil, error: nil, expandedFiles: [], diffs: [:])).files == .loading)
    }
}
