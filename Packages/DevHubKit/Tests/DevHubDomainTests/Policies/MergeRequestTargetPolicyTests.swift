import Testing
@testable import DevHubDomain

@Suite struct MergeRequestTargetPolicyTests {
    @Test func devComesFirstThenTheBaseThenTheRestSorted() {
        let targets = MergeRequestTargetPolicy.targets(
            remoteBranches: ["origin/release/2.0", "origin/main", "origin/feature/x", "origin/dev", "origin/staging"],
            source: "feature/x",
            baseName: "staging"
        )

        #expect(targets == ["dev", "staging", "main", "release/2.0"])
    }

    @Test func theSourceAndHEADAreNotTargets() {
        let targets = MergeRequestTargetPolicy.targets(
            remoteBranches: ["origin/HEAD", "origin/dev", "origin/feature/x"],
            source: "origin/feature/x",
            baseName: "dev"
        )

        #expect(targets == ["dev"])
    }

    @Test func withoutRemoteBranchesTheBaseIsTheOnlyTarget() {
        #expect(MergeRequestTargetPolicy.targets(remoteBranches: [], source: "feature/x", baseName: "dev") == ["dev"])
        #expect(MergeRequestTargetPolicy.targets(remoteBranches: [], source: "dev", baseName: "dev").isEmpty)
    }
}
