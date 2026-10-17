import DevHubDomain
import DevHubUI
import Foundation
import Testing
@testable import DevHubPresentation

@Suite struct LocalBranchRowMapperTests {
    @Test func plainTrackedBranch() {
        let model = row(GitBranchFixture.feature, current: "dev", worktree: nil)

        #expect(model.id == "feature/login")
        #expect(model.name == "feature/login")
        #expect(model.icon == "arrow.triangle.branch")
        #expect(model.iconHint == "Local branch")
        #expect(model.usesAccentIcon == false)
        #expect(model.tags.isEmpty)
        #expect(model.dateText == nil)
        #expect(model.subject == "ABC-1: Login screen")
        #expect(model.worktreePath == nil)
        #expect(model.switchHint == "Switch to this branch")
        #expect(model.canSwitch)
        #expect(model.canUpdate)
        #expect(model.canBuild)
        #expect(model.canCreateWorktree)
        #expect(model.canDelete)
        #expect(model.canOpenPullRequest)
        #expect(model.pullRequestHint == "New merge request: title, description and labels in DevHub")
        #expect(model.pullRequestIconTint == nil)
        #expect(model.pullRequestMenuTitle == "New Merge Request…")
        #expect(model.existingPullRequest == nil)
        #expect(model.areActionsEnabled)
        #expect(model.deleteMessage == "Delete feature/login? It is not merged into dev; without force git refuses.")
        #expect(model.showsForceToggle)
    }

    @Test func currentBranch() {
        var branch = GitBranchFixture.feature
        branch.worktreePath = "/Users/dev/Projects/ExampleApp"

        let model = row(branch, current: "feature/login", worktree: WorktreeFixture.main)

        #expect(model.icon == "checkmark.circle.fill")
        #expect(model.iconHint == "Checked out here")
        #expect(model.usesAccentIcon)
        #expect(model.tags == [TagModel("current", tint: .blue)])
        #expect(model.switchHint == "Switch to this branch")
        #expect(model.canSwitch == false)
        #expect(model.canCreateWorktree == false)
        #expect(model.canDelete == false)
    }

    @Test func branchInAnotherWorktree() {
        var branch = GitBranchFixture.feature
        branch.worktreePath = WorktreeFixture.linked.path
        var worktree = WorktreeFixture.linked
        worktree.changedFiles = 2

        let model = row(branch, current: "dev", worktree: worktree)

        #expect(model.icon == "rectangle.stack")
        #expect(model.iconHint == "Checked out in another worktree")
        #expect(model.tags == [
            TagModel("worktree", tint: .teal, systemImage: "rectangle.stack", hint: WorktreeFixture.linked.path),
            TagModel("2 changed there", tint: .orange)
        ])
        #expect(model.worktreePath == WorktreeFixture.linked.path)
        #expect(model.switchHint == "Checked out in another worktree")
        #expect(model.canSwitch == false)
        #expect(model.canCreateWorktree == false)
        #expect(model.canDelete == false)
    }

    @Test func branchInTheMainCheckout() {
        var branch = GitBranchFixture.feature
        branch.worktreePath = WorktreeFixture.main.path

        let model = row(branch, current: "other", worktree: WorktreeFixture.main)

        #expect(model.tags == [TagModel("main checkout", tint: .teal, systemImage: "rectangle.stack", hint: WorktreeFixture.main.path)])
    }

    @Test func mergedAndGoneBranch() {
        var branch = GitBranchFixture.feature
        branch.isGone = true
        branch.isMerged = true

        let model = row(branch, current: nil, worktree: nil)

        #expect(model.tags == [
            TagModel("remote deleted", tint: .purple, systemImage: "icloud.slash", hint: "Its branch on the remote was deleted, usually after the merge request was merged"),
            TagModel("merged", tint: .purple, systemImage: "arrow.triangle.merge", hint: "All its commits are in dev. Safe to delete.")
        ])
        #expect(model.canUpdate == false)
        #expect(model.canOpenPullRequest == false)
        #expect(model.deleteMessage == "Delete local branch feature/login?")
        #expect(model.showsForceToggle == false)
    }

    @Test func goneButNotMergedStillOffersForce() {
        var branch = GitBranchFixture.feature
        branch.isGone = true

        let model = row(branch, current: nil, worktree: nil)

        #expect(model.deleteMessage == "Delete local branch feature/login?")
        #expect(model.showsForceToggle)
    }

    @Test func localOnlyBranchAheadAndBehind() {
        var branch = GitBranchFixture.feature
        branch.upstream = nil
        branch.ahead = 2
        branch.behind = 1

        let model = row(branch, current: nil, worktree: nil)

        #expect(model.tags == [
            TagModel("local only", tint: .orange, systemImage: "icloud.slash", hint: "Never pushed: the commits exist only on this Mac"),
            TagModel("↑2", tint: .blue, hint: "2 commits not pushed"),
            TagModel("↓1", tint: .orange, hint: "Behind its remote. Update fast-forwards it without switching.")
        ])
        #expect(model.canUpdate == false)
        #expect(model.canOpenPullRequest == false)
        #expect(model.pullRequestHint == "Push the branch first: a merge request needs it on the remote")
    }

    @Test func branchWithAnOpenPullRequest() {
        var branch = GitBranchFixture.feature
        branch.upstream = nil
        let request = PullRequestSummaryFixture.open

        let model = row(branch, current: nil, worktree: nil, openPullRequest: request)

        #expect(model.pullRequest == BranchPullRequestMapper.model(for: request, words: .gitLab))
        #expect(model.tags.contains { $0.text == "!21" } == false)
        #expect(model.canOpenPullRequest)
        #expect(model.pullRequestHint == "Merge request !21 into dev is open")
        #expect(model.pullRequestIconTint == .blue)
        #expect(model.pullRequestMenuTitle == "Show Merge Request…")
        #expect(model.existingPullRequest == ExistingPullRequestModel(
            message: "Merge request !21 into dev already exists: ABC-5: Login",
            openTitle: "Open !21",
            url: request.webURL
        ))
    }

    @Test func dateTextPrefersLastVisit() throws {
        var branch = GitBranchFixture.feature
        branch.commitDate = Date(timeIntervalSinceNow: -7_200)

        let commit = try #require(row(branch, current: nil, worktree: nil).dateText)
        branch.lastVisited = Date(timeIntervalSinceNow: -60)
        let visited = try #require(row(branch, current: nil, worktree: nil).dateText)

        #expect(commit.hasPrefix("committed "))
        #expect(visited.hasPrefix("visited "))
        #expect(visited.contains(" · committed "))
    }

    @Test func dateTextNamesTheAuthor() throws {
        var branch = GitBranchFixture.feature
        branch.commitDate = Date(timeIntervalSinceNow: -7_200)
        branch.author = "kim"

        let text = try #require(row(branch, current: nil, worktree: nil).dateText)

        #expect(text.hasPrefix("committed "))
        #expect(text.hasSuffix(" by kim"))
        #expect(row(GitBranchFixture.feature, current: nil, worktree: nil).dateText == nil)
    }

    @Test func configActionsPassThrough() {
        #expect(row(GitBranchFixture.feature, current: nil, worktree: nil, configActions: [.preview]).configActions == [.preview])
        #expect(row(GitBranchFixture.feature, current: nil, worktree: nil).configActions.isEmpty)
    }

    @Test func buildAndBusyFlags() {
        let model = LocalBranchRowMapper.model(
            for: GitBranchFixture.feature,
            currentBranch: nil,
            worktree: nil,
            openPullRequest: nil,
            baseName: "dev",
            changedFiles: 0,
            ticket: .standard,
            words: .gitLab,
            isBuildRunning: true,
            isBusy: true,
            configActions: []
        )

        #expect(model.canBuild == false)
        #expect(model.areActionsEnabled == false)
    }

    @Test func aTicketBranchGetsAChipThatCopiesWithoutATemplate() {
        var branch = GitBranchFixture.feature
        branch.name = "feature/ABC-2324-paid-call"

        #expect(row(branch, current: nil, worktree: nil).ticket == TicketModel(key: "ABC-2324", url: nil, hint: "Copy ABC-2324. Set git.ticketURL in .devhub/project.json or the ticket link in Settings to open it."))
        #expect(row(GitBranchFixture.feature, current: nil, worktree: nil).ticket == nil)
    }

    @Test func switchingWithChangesAsksFirst() {
        #expect(row(GitBranchFixture.feature, current: "dev", worktree: nil).switchConfirmation == nil)
        #expect(row(GitBranchFixture.feature, current: "dev", worktree: nil, changedFiles: 3).switchConfirmation == "You have 3 changed files. Stash them, switch to feature/login and bring them back?")
        #expect(row(GitBranchFixture.feature, current: "dev", worktree: nil, changedFiles: 1).switchConfirmation?.hasPrefix("You have 1 changed file.") == true)
    }

    private func row(_ branch: GitBranch, current: String?, worktree: Worktree?, openPullRequest: PullRequestSummary? = nil, changedFiles: Int = 0, configActions: [ConfigActionItemModel] = []) -> LocalBranchRowModel {
        LocalBranchRowMapper.model(
            for: branch,
            currentBranch: current,
            worktree: worktree,
            openPullRequest: openPullRequest,
            baseName: "dev",
            changedFiles: changedFiles,
            ticket: .standard,
            words: .gitLab,
            isBuildRunning: false,
            isBusy: false,
            configActions: configActions
        )
    }
}
