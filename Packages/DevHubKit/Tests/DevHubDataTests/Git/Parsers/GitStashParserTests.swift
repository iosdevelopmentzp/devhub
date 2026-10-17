import DevHubDomain
import Foundation
import Testing
@testable import DevHubData

@Suite struct GitStashParserTests {
    @Test func readsIndexBranchMessageAndDate() {
        let output = [
            "stash@{0}\t1700000000\tOn feature/login: half done: the form",
            "stash@{1}\t1600000000\tWIP on dev: a1b2c3d ABC-5: Fix the crash",
            "stash@{2}\t\tOn (no branch): detached work",
            "broken line",
            "stash@{x}\t1\tOn a: b",
        ].joined(separator: "\n")

        let stashes = GitStashParser.parse(output)

        #expect(stashes == [
            GitStash(index: 0, branch: "feature/login", message: "half done: the form", date: Date(timeIntervalSince1970: 1_700_000_000)),
            GitStash(index: 1, branch: "dev", message: "WIP: ABC-5: Fix the crash", date: Date(timeIntervalSince1970: 1_600_000_000)),
            GitStash(index: 2, branch: nil, message: "detached work", date: nil),
        ])
    }

    @Test func anUnknownSubjectIsTheMessage() {
        #expect(GitStashParser.parse("stash@{4}\t1\tautostash") == [GitStash(index: 4, branch: nil, message: "autostash", date: Date(timeIntervalSince1970: 1))])
    }

    @Test func emptyOutputHasNoStashes() {
        #expect(GitStashParser.parse("").isEmpty)
    }
}
