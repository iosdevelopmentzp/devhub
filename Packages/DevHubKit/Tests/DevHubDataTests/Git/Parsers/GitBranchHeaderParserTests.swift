import DevHubDomain
import Testing
@testable import DevHubData

@Suite struct GitBranchHeaderParserTests {
    @Test func readsBranchHeaderAndCountsFiles() {
        let snapshot = GitBranchHeaderParser.parse(GitStatusFixture.headerV2, base: "origin/dev")

        #expect(snapshot.head == "012345678")
        #expect(snapshot.branch == "feature/ABC-1")
        #expect(snapshot.upstream == "origin/feature/ABC-1")
        #expect(snapshot.ahead == 2)
        #expect(snapshot.behind == 3)
        #expect(snapshot.changedFiles == 3)
        #expect(snapshot.baseBranch == "origin/dev")
    }

    @Test func detachedHeadHasNoBranch() {
        let snapshot = GitBranchHeaderParser.parse(GitStatusFixture.detachedHeaderV2, base: "origin/main")

        #expect(snapshot.branch == nil)
        #expect(snapshot.head == "fedcba987")
        #expect(snapshot.upstream == nil)
        #expect(snapshot.changedFiles == 0)
    }

    @Test func leavesFieldsOutsideTheHeaderAtDefaults() {
        let snapshot = GitBranchHeaderParser.parse("", base: "origin/dev")

        #expect(snapshot.head == "")
        #expect(snapshot.ahead == 0)
        #expect(snapshot.stashCount == 0)
        #expect(snapshot.operation == nil)
        #expect(snapshot.aheadOfBase == 0)
        #expect(snapshot.behindBase == 0)
        #expect(snapshot.lastFetch == nil)
        #expect(snapshot.webURL == nil)
    }
}
