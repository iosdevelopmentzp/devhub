import DevHubDomain
import Testing
@testable import DevHubData

@Suite struct GitContainingBranchesParserTests {
    @Test func localAndRemoteBranchesAreKeptAndTheRemoteHeadIsDropped() {
        let output = "refs/heads/main\nrefs/heads/feature/ABC-123-short-title\nrefs/remotes/origin/HEAD\nrefs/remotes/origin/main\n  refs/heads/dev \nrefs/tags/v1\n"

        #expect(GitContainingBranchesParser.parse(output) == [
            GitCommitRef(kind: .localBranch, name: "main"),
            GitCommitRef(kind: .localBranch, name: "feature/ABC-123-short-title"),
            GitCommitRef(kind: .remoteBranch, name: "origin/main"),
            GitCommitRef(kind: .localBranch, name: "dev"),
        ])
        #expect(GitContainingBranchesParser.parse("").isEmpty)
    }
}
