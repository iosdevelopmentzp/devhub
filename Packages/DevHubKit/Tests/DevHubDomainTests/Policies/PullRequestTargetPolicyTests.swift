import Testing
@testable import DevHubDomain

@Suite struct PullRequestTargetPolicyTests {
    @Test func devComesFirstThenTheBaseThenTheRestSorted() {
        let targets = PullRequestTargetPolicy.targets(
            remoteBranches: ["origin/release/2.0", "origin/main", "origin/feature/x", "origin/dev", "origin/staging"],
            source: "feature/x",
            baseName: "staging",
            remote: "origin"
        )

        #expect(targets == ["dev", "staging", "main", "release/2.0"])
    }

    @Test func theSourceAndHEADAreNotTargets() {
        let targets = PullRequestTargetPolicy.targets(
            remoteBranches: ["origin/HEAD", "origin/dev", "origin/feature/x"],
            source: "origin/feature/x",
            baseName: "dev",
            remote: "origin"
        )

        #expect(targets == ["dev"])
    }

    @Test func withoutRemoteBranchesTheBaseIsTheOnlyTarget() {
        #expect(PullRequestTargetPolicy.targets(remoteBranches: [], source: "feature/x", baseName: "dev", remote: "origin") == ["dev"])
        #expect(PullRequestTargetPolicy.targets(remoteBranches: [], source: "dev", baseName: "dev", remote: "origin").isEmpty)
    }
}
