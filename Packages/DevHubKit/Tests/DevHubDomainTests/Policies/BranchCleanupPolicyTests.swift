import DevHubDomain
import Testing

@Suite struct BranchCleanupPolicyTests {
    @Test func mergedAndGoneBranchesAreCandidates() {
        let branches = [branch("merged", merged: true), branch("gone", gone: true), branch("active")]

        let names = BranchCleanupPolicy.candidates(branches: branches, currentBranch: nil, baseName: "dev", protected: ["main", "master", "develop", "dev"]).map(\.name)

        #expect(names == ["merged", "gone"])
    }

    @Test func currentCheckedOutBaseAndProtectedBranchesStay() {
        let branches = [
            branch("current", merged: true),
            branch("in-worktree", merged: true, worktree: "/wt/a"),
            branch("develop", merged: true),
            branch("dev", merged: true),
            branch("main", gone: true),
            branch("master", merged: true),
            branch("old", merged: true),
        ]

        let names = BranchCleanupPolicy.candidates(branches: branches, currentBranch: "current", baseName: "develop", protected: ["main", "master", "develop", "dev"]).map(\.name)

        #expect(names == ["old"])
    }

    @Test func aConfiguredListReplacesTheDefaultButKeepsTheBase() {
        let branches = [branch("main", merged: true), branch("release", merged: true), branch("develop", merged: true)]

        let names = BranchCleanupPolicy.candidates(branches: branches, currentBranch: nil, baseName: "develop", protected: ["release"]).map(\.name)

        #expect(names == ["main"])
    }

    @Test func forceAppliesOnlyToGoneBranchesWhenAsked() {
        #expect(BranchCleanupPolicy.usesForce(branch("gone", gone: true), forceGone: true))
        #expect(BranchCleanupPolicy.usesForce(branch("gone", gone: true), forceGone: false) == false)
        #expect(BranchCleanupPolicy.usesForce(branch("merged", merged: true), forceGone: true) == false)
    }

    private func branch(_ name: String, merged: Bool = false, gone: Bool = false, worktree: String? = nil) -> GitBranch {
        var branch = GitBranchFixture.local(name)
        branch.isMerged = merged
        branch.isGone = gone
        branch.worktreePath = worktree
        return branch
    }
}
