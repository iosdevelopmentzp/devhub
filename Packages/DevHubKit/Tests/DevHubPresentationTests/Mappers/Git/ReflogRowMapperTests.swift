import DevHubDomain
import DevHubUI
import Foundation
import Testing
@testable import DevHubPresentation

@Suite struct ReflogRowMapperTests {
    @Test func entryShowsTheSelectorActionAndMessage() {
        let entry = GitReflogEntry(index: 2, hash: "a1b2c3", shortHash: "a1b", date: Date(timeIntervalSinceNow: -60), action: "checkout", message: "moving from dev to main")

        let model = ReflogRowMapper.model(for: entry, expansion: nil)

        #expect(model.id == 2)
        #expect(model.selector == "HEAD@{2}")
        #expect(model.actionTag == TagModel("checkout", tint: .blue))
        #expect(model.message == "moving from dev to main")
        #expect(model.dateText?.isEmpty == false)
        #expect(model.files == nil)
    }

    @Test(arguments: [
        ("commit", Tint.green),
        ("commit (amend)", .orange),
        ("rebase (finish)", .orange),
        ("reset", .red),
        ("pull", .purple),
        ("cherry-pick", .purple),
        ("branch", .secondary),
    ])
    func actionGetsItsTint(action: String, tint: Tint) {
        let entry = GitReflogEntry(index: 0, hash: "a", shortHash: "a", date: nil, action: action, message: "")

        #expect(ReflogRowMapper.model(for: entry, expansion: nil).actionTag.tint == tint)
    }

    @Test func resetExplainsThatCommitsCanBeRestored() {
        let entry = GitReflogEntry(index: 0, hash: "a", shortHash: "a", date: nil, action: "reset", message: "moving to HEAD~1")

        #expect(ReflogRowMapper.model(for: entry, expansion: nil).actionTag.hint?.contains("restored") == true)
    }

    @Test func expandedEntryListsTheCommitFiles() {
        let entry = GitReflogEntry(index: 0, hash: "a1b2c3", shortHash: "a1b", date: nil, action: "commit", message: "")
        let expansion = CommitRowMapper.Expansion(files: [], error: nil, expandedFiles: [], diffs: [:])

        #expect(ReflogRowMapper.model(for: entry, expansion: expansion).files == .note("No file changes in this commit"))
    }
}
