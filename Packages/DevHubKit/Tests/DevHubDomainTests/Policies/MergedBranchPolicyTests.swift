import Testing
@testable import DevHubDomain

@Suite struct MergedBranchPolicyTests {
    @Test func mergedPushedBranchWithNothingAheadIsMerged() {
        #expect(MergedBranchPolicy.isMerged(branch: "feature", upstream: "origin/feature", ahead: 0, mergedBranches: ["feature"], remote: "origin"))
    }

    @Test func branchOutsideTheMergedSetIsNotMerged() {
        #expect(MergedBranchPolicy.isMerged(branch: "feature", upstream: "origin/feature", ahead: 0, mergedBranches: ["other"], remote: "origin") == false)
    }

    @Test func branchWithoutUpstreamIsNotMerged() {
        #expect(MergedBranchPolicy.isMerged(branch: "feature", upstream: nil, ahead: 0, mergedBranches: ["feature"], remote: "origin") == false)
    }

    @Test func branchTrackingAnotherNameIsNotMerged() {
        #expect(MergedBranchPolicy.isMerged(branch: "feature", upstream: "origin/other", ahead: 0, mergedBranches: ["feature"], remote: "origin") == false)
    }

    @Test func branchWithLocalCommitsIsNotMerged() {
        #expect(MergedBranchPolicy.isMerged(branch: "feature", upstream: "origin/feature", ahead: 1, mergedBranches: ["feature"], remote: "origin") == false)
    }
}
