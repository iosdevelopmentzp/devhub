import DevHubDomain
import DevHubUI
import Testing
@testable import DevHubPresentation

@Suite struct CommitFileRowMapperTests {
    @Test func renamedFileShowsTheOldPath() {
        let file = GitCommitFile(path: "Docs/new.md", originalPath: "Docs/old.md", kind: .renamed)

        let model = CommitFileRowMapper.model(for: file, hash: "abc", isExpanded: false, diff: nil)

        #expect(model.id == CommitFileKey(hash: "abc", path: "Docs/new.md"))
        #expect(model.letter == "R")
        #expect(model.letterTint == .blue)
        #expect(model.letterHint == "Renamed")
        #expect(model.fileName == "new.md")
        #expect(model.detail == "Docs/old.md →")
        #expect(model.diff == nil)
    }

    @Test func expandedFileWithoutADiffIsLoading() {
        let file = GitCommitFile(path: "App/Gift.swift", originalPath: nil, kind: .added)

        let model = CommitFileRowMapper.model(for: file, hash: "abc", isExpanded: true, diff: nil)

        #expect(model.detail == "App")
        #expect(model.letterTint == .green)
        #expect(model.diff == .loading)
        #expect(model.isExpanded)
    }
}
