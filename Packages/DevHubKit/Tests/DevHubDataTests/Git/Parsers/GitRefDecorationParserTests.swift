import DevHubDomain
import Testing
@testable import DevHubData

@Suite struct GitRefDecorationParserTests {
    @Test func readsHeadBranchesAndTags() {
        let decoration = "HEAD -> refs/heads/feature/login, refs/remotes/origin/feature/login, refs/remotes/origin/HEAD, tag: refs/tags/v4.12, refs/stash"

        #expect(GitRefDecorationParser.parse(decoration) == [
            GitCommitRef(kind: .head, name: "HEAD"),
            GitCommitRef(kind: .localBranch, name: "feature/login"),
            GitCommitRef(kind: .remoteBranch, name: "origin/feature/login"),
            GitCommitRef(kind: .tag, name: "v4.12"),
        ])
    }

    @Test func detachedHeadStandsAlone() {
        #expect(GitRefDecorationParser.parse("HEAD") == [GitCommitRef(kind: .head, name: "HEAD")])
    }

    @Test func noDecorationHasNoRefs() {
        #expect(GitRefDecorationParser.parse("").isEmpty)
    }
}
