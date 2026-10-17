import Testing
@testable import DevHubData

@Suite struct WorktreePorcelainParserTests {
    private let entries = WorktreePorcelainParser.parse(WorktreePorcelainFixture.listing)

    @Test func parsesEveryEntry() {
        #expect(entries.map(\.path) == [
            "/Users/me/App",
            "/Users/me/App/.claude/worktrees/feature-x",
            "/Users/me/App-detached",
            "/Users/me/App-locked",
        ])
    }

    @Test func stripsBranchPrefix() {
        #expect(entries.map(\.branch) == ["main", "feature/x", nil, "locked"])
    }

    @Test func readsHead() {
        #expect(entries.first?.head == "0123456789abcdef")
    }

    @Test func readsLockedAndPrunableFlags() {
        #expect(entries.map(\.isLocked) == [false, true, false, true])
        #expect(entries.map(\.isPrunable) == [false, false, true, true])
    }

    @Test func emptyOutputHasNoEntries() {
        #expect(WorktreePorcelainParser.parse("").isEmpty)
    }
}
