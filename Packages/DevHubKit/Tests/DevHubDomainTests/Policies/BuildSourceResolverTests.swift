import Testing
@testable import DevHubDomain

@Suite struct BuildSourceResolverTests {
    private let feature = WorktreeFixture.linked(branch: "feature")

    @Test func checkoutPathFindsTheWorktreeOfTheLocalBranch() {
        let path = BuildSourceResolver.checkoutPath(forBranch: "origin/feature", in: [WorktreeFixture.main, feature], remote: "origin")

        #expect(path == feature.path)
    }

    @Test func checkoutPathSkipsAMissingWorktree() {
        var missing = feature
        missing.isMissing = true

        #expect(BuildSourceResolver.checkoutPath(forBranch: "feature", in: [missing], remote: "origin") == nil)
    }

    @Test func checkoutPathIsNilWhenNoWorktreeHasTheBranch() {
        #expect(BuildSourceResolver.checkoutPath(forBranch: "other", in: [WorktreeFixture.main, feature], remote: "origin") == nil)
    }

    @Test func mainUsesTheMainCheckoutAndTheMainWorktreeName() {
        let resolution = resolve(.main, worktrees: [WorktreeFixture.main, feature])

        #expect(resolution == .init(path: "/main", worktreeID: nil, label: "dev · main checkout"))
    }

    @Test func mainFallsBackToTheProjectNameWithoutAMainWorktree() {
        let resolution = resolve(.main, worktrees: [feature])

        #expect(resolution == .init(path: "/main", worktreeID: nil, label: "App · main checkout"))
    }

    @Test func worktreeUsesItsPathWhenAvailable() {
        let resolution = resolve(.worktree(feature.path), worktrees: [WorktreeFixture.main, feature])

        #expect(resolution == .init(path: feature.path, worktreeID: feature.path, label: "feature"))
    }

    @Test func missingWorktreeBuildsTheMainCheckoutButKeepsItsID() {
        var missing = feature
        missing.isMissing = true

        let resolution = resolve(.worktree(missing.path), worktrees: [missing])

        #expect(resolution == .init(path: "/main", worktreeID: missing.path, label: "feature"))
    }

    @Test func unknownWorktreeIsLabelledWithTheFolderName() {
        let resolution = resolve(.worktree("/somewhere/old-tree"), worktrees: [feature])

        #expect(resolution == .init(path: "/main", worktreeID: "/somewhere/old-tree", label: "old-tree"))
    }

    @Test func branchWithALinkedWorktreeUsesThatWorktree() {
        let resolution = resolve(.branch("origin/feature"), worktrees: [WorktreeFixture.main, feature])

        #expect(resolution == .init(path: feature.path, worktreeID: feature.path, label: "origin/feature"))
    }

    @Test func branchCheckedOutInTheMainWorktreeHasNoWorktreeID() {
        let resolution = resolve(.branch("dev"), worktrees: [WorktreeFixture.main, feature])

        #expect(resolution == .init(path: WorktreeFixture.mainPath, worktreeID: nil, label: "dev"))
    }

    @Test func branchWithoutAWorktreeFallsBackToMainAndSaysANewOneIsCreated() {
        let resolution = resolve(.branch("new"), worktrees: [WorktreeFixture.main, feature])

        #expect(resolution == .init(path: "/main", worktreeID: nil, label: "new · new worktree on run"))
    }

    private func resolve(_ source: BuildSourceChoice, worktrees: [Worktree]) -> BuildSourceResolver.BuildSourceResolution {
        BuildSourceResolver.resolve(source: source, worktrees: worktrees, mainCheckoutPath: "/main", projectName: "App", remote: "origin")
    }
}
