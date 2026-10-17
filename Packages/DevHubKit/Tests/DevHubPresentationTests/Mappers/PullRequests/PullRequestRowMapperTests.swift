import DevHubDomain
import DevHubUI
import Foundation
import Testing
import DevHubTestSupport
@testable import DevHubPresentation

@Suite struct PullRequestRowMapperTests {
    private let now = Date(timeIntervalSince1970: 1_000_000_000)

    @Test func openRequestWithStatusAndThreads() {
        let request = PullRequestSummaryFixture.request(iid: 7, source: "feature/login", state: .opened, hasConflicts: true, detail: .notApproved, comments: 3, threadCount: 2, resolvedThreadCount: 1)

        let model = map(request, username: "sam", scope: .all)

        #expect(model.id == 7)
        #expect(model.reference == "!7")
        #expect(model.title == "ABC-5: Login")
        #expect(model.icon == "arrow.triangle.pull")
        #expect(model.iconTint == Tint.blue)
        #expect(model.iconHint == "Open")
        #expect(model.author == "sam")
        #expect(model.authorTint == .blue)
        #expect(model.authorHint == "Opened by you")
        #expect(model.targetBranch == "dev")
        #expect(model.sourceBranch == "feature/login")
        #expect(model.dateText == nil)
        #expect(model.dateHint == nil)
        #expect(model.statsText == nil)
        #expect(model.isNew == false)
        #expect(model.tags == [
            TagModel("conflicts", tint: .red, systemImage: "exclamationmark.triangle.fill", hint: "GitLab cannot merge it: rebase on dev and solve the conflicts"),
            TagModel("needs approval", tint: .orange, hint: "GitLab merge status: not_approved"),
            TagModel("1 open thread", tint: .orange, systemImage: "bubble.left.and.bubble.right", hint: "1 of 2 threads resolved, 3 comments in all"),
        ])
        #expect(model.pipelineTag == nil)
        #expect(model.labelTags.isEmpty)
        #expect(model.webURL == request.webURL)
        #expect(model.canCheckOut)
        #expect(model.isExpanded == false)
        #expect(model.hasTags)
    }

    @Test func theOpenThreadsTagReplacesTheMergeStatusTag() {
        let request = PullRequestSummaryFixture.request(iid: 7, source: "x", state: .opened, author: "me", detail: .discussionsNotResolved, comments: 9, threadCount: 3)
        let resolved = PullRequestSummaryFixture.request(iid: 7, source: "x", state: .opened, author: "me", detail: .discussionsNotResolved, comments: 9)

        #expect(map(request).tags.map(\.text) == ["3 open threads"])
        #expect(map(resolved).tags.map(\.text) == ["open threads"])
    }

    @Test func theAuthorIsHiddenInMine() {
        let request = PullRequestSummaryFixture.request(iid: 7, source: "x", state: .opened, author: "me")

        #expect(map(request, scope: .mine).author == "")
        #expect(map(request, scope: .mine).authorHint == "Opened by you")
        #expect(map(request, scope: .all).author == "me")
    }

    @Test func pipelineApprovalsLabelsAndReview() {
        let pipelineURL = URL(string: "https://gitlab.example.com/team/app/-/pipelines/9")
        let request = PullRequestSummaryFixture.request(
            iid: 7,
            source: "x",
            state: .opened,
            pipeline: PipelineInfo(status: .failed, webURL: pipelineURL, updatedAt: nil, failedJobCount: 2),
            approvedBy: ["kim"],
            labels: ["feature", "tech"]
        )

        let model = map(request, isExpanded: true)

        #expect(model.pipelineTag == TagModel("pipeline failed", tint: .red, systemImage: "xmark.circle.fill", hint: "2 jobs failed. Click to open it."))
        #expect(model.pipelineURL == pipelineURL)
        #expect(model.authorTint == nil)
        #expect(model.authorHint == "Opened by sam")
        #expect(model.tags == [
            TagModel("needs your review", tint: .indigo, systemImage: "eye", hint: "Opened by sam, not a draft, you have not approved it"),
            TagModel("approved by kim", tint: .green, systemImage: "checkmark.seal.fill", hint: "Approved by kim"),
        ])
        #expect(model.labelTags == [TagModel("feature", tint: .secondary, systemImage: "tag", hint: "Label on GitLab"), TagModel("tech", tint: .secondary, systemImage: "tag", hint: "Label on GitLab")])
        #expect(model.isExpanded)
    }

    @Test(arguments: [PipelineStatus.success, .running, .pending, .failed])
    func everyPipelineIsShown(status: PipelineStatus) {
        let url = URL(string: "https://gitlab.example.com/p/1")
        let request = PullRequestSummaryFixture.request(iid: 7, source: "x", state: .opened, pipeline: PipelineInfo(status: status, webURL: url, updatedAt: nil))

        let model = map(request)

        #expect(model.pipelineTag == PullRequestTagMapper.compactPipelineTag(request.pipeline!, words: .gitLab))
        #expect(model.pipelineURL == url)
    }

    @Test func actionsMergeDefaultsAndBusyState() {
        let request = PullRequestSummaryFixture.request(iid: 7, source: "x", state: .opened, detail: .mergeable, squashOnMerge: true, removesSourceBranch: false)

        let model = map(request, isBusy: true)

        #expect(model.primaryActions.map(\.id) == [.approve, .merge])
        #expect(model.actions.map(\.id) == [.markDraft, .rebase])
        #expect(model.mergeTitle == "Merge !7 into dev?")
        #expect(model.squashByDefault)
        #expect(model.removeSourceBranchByDefault == false)
        #expect(model.isBusy)
        #expect(map(PullRequestSummaryFixture.request(iid: 7, source: "x", state: .merged)).actions.isEmpty)
    }

    @Test func anUnsetBranchRemovalDefaultsToOn() {
        let request = PullRequestSummaryFixture.request(iid: 7, source: "x", state: .opened)

        #expect(map(request).removeSourceBranchByDefault)
        #expect(map(request).squashByDefault == false)
    }

    @Test func readyToMergeIsAGreenTag() {
        let request = PullRequestSummaryFixture.request(iid: 7, source: "x", state: .opened, author: "me", detail: .mergeable)

        #expect(map(request).tags == [TagModel("ready to merge", tint: .green, hint: "GitLab merge status: mergeable")])
    }

    @Test func theReviewQueueHidesTheReviewTag() {
        let request = PullRequestSummaryFixture.request(iid: 7, source: "x", state: .opened)

        #expect(map(request, scope: .reviewing).tags.isEmpty)
    }

    @Test func myApprovalIsShownAsYou() {
        let request = PullRequestSummaryFixture.request(iid: 7, source: "x", state: .opened, approvedBy: ["me", "kim"])

        #expect(map(request).tags == [TagModel("you approved", tint: .green, systemImage: "checkmark.seal.fill", hint: "Approved by you, kim")])
    }

    @Test func sizeCommitsAndAge() {
        let request = PullRequestSummaryFixture.request(
            iid: 7,
            source: "x",
            state: .opened,
            author: "me",
            updatedAt: now.addingTimeInterval(-3_600),
            createdAt: now.addingTimeInterval(-12 * 86_400),
            commitCount: 3,
            diffStats: DiffStats(additions: 120, deletions: 30, fileCount: 7)
        )

        let model = map(request)

        #expect(model.statsText == "+120 −30 · 7 files · 3 commits")
        #expect(model.dateText?.hasPrefix("updated ") == true)
        #expect(model.dateHint?.hasPrefix("opened ") == true)
    }

    @Test func oneFileAndOneCommitAreSingular() {
        let request = PullRequestSummaryFixture.request(iid: 7, source: "x", state: .opened, commitCount: 1, diffStats: DiffStats(additions: 1, deletions: 0, fileCount: 1))

        #expect(map(request).statsText == "+1 −0 · 1 file · 1 commit")
    }

    @Test func behindAndStaleRequests() {
        let request = PullRequestSummaryFixture.request(iid: 7, source: "x", state: .opened, author: "me", updatedAt: now.addingTimeInterval(-15 * 86_400), isBehindTarget: true)

        #expect(map(request).tags.map(\.text) == ["behind dev", "stale"])
        #expect(map(request).tags.map(\.tint) == [.orange, .orange])
    }

    @Test func aMergedRequestNamesWhoMergedIt() {
        let request = PullRequestSummaryFixture.request(iid: 7, source: "x", state: .merged, updatedAt: now, mergedAt: now.addingTimeInterval(-86_400), mergedBy: "kim", isBehindTarget: true)
        let closed = PullRequestSummaryFixture.request(iid: 7, source: "x", state: .closed, updatedAt: now, closedAt: now.addingTimeInterval(-86_400))

        #expect(map(request).dateText?.hasPrefix("merged by kim ") == true)
        #expect(map(request).tags == [TagModel("merged", tint: .purple)])
        #expect(map(closed).dateText?.hasPrefix("closed ") == true)
    }

    @Test func aRequestUpdatedAfterTheLastVisitIsNew() {
        let request = PullRequestSummaryFixture.request(iid: 7, source: "x", state: .opened, updatedAt: now)

        #expect(map(request, seenAt: now.addingTimeInterval(-60)).isNew)
        #expect(map(request, seenAt: now.addingTimeInterval(60)).isNew == false)
        #expect(map(request, seenAt: nil).isNew == false)
    }

    @Test func draftRequest() {
        let request = PullRequestSummaryFixture.request(iid: 1, source: "x", state: .opened, isDraft: true, detail: .draftStatus)

        let model = map(request)

        #expect(model.iconTint == Tint.gray)
        #expect(model.iconHint == "Draft")
        #expect(model.tags == [TagModel("draft", tint: .gray, hint: "Draft: not ready for review")])
    }

    @Test(arguments: ["unchecked", "checking"])
    func pendingMergeCheckHasNoTag(status: String) {
        let request = PullRequestSummaryFixture.request(iid: 1, source: "x", state: .opened, author: "me", detail: .other(status))

        #expect(map(request).tags.isEmpty)
    }

    @Test(arguments: [
        (PullRequestState.merged, "arrow.triangle.merge", Tint.purple, "Merged"),
        (.closed, "xmark.circle", .secondary, "Closed"),
    ])
    func finishedRequest(state: PullRequestState, icon: String, tint: Tint, hint: String) {
        let request = PullRequestSummaryFixture.request(iid: 1, source: "x", state: state, hasConflicts: true, detail: .needRebase, threadCount: 2)

        let model = map(request)

        #expect(model.icon == icon)
        #expect(model.iconTint == tint)
        #expect(model.iconHint == hint)
        #expect(model.tags == [TagModel(state.name, tint: tint)])
        #expect(model.canCheckOut == false)
    }

    @Test func autoMergeHasABlueTag() {
        let request = PullRequestSummaryFixture.request(iid: 7, source: "x", state: .opened, author: "me", isAutoMergeEnabled: true)

        let model = map(request)

        #expect(model.tags.map(\.text) == ["auto-merge"])
        #expect(model.tags.map(\.tint) == [.blue])
        #expect(model.autoMergeTitle == "Merge !7 into dev when the pipeline passes?")
    }

    @Test func fixThreadsNeedsAnOpenRequestWithOpenThreads() {
        let open = PullRequestSummaryFixture.request(iid: 7, source: "x", state: .opened, threadCount: 3, resolvedThreadCount: 1)
        let resolved = PullRequestSummaryFixture.request(iid: 7, source: "x", state: .opened, threadCount: 2, resolvedThreadCount: 2)
        let merged = PullRequestSummaryFixture.request(iid: 7, source: "x", state: .merged, threadCount: 3)

        #expect(map(open, local: .none).canFixThreads)
        #expect(map(resolved, local: .none).canFixThreads == false)
        #expect(map(merged, local: .none).canFixThreads == false)
    }

    @Test func localStateAddsATealTagAndChoosesTheActions() {
        let request = PullRequestSummaryFixture.request(iid: 7, source: "x", state: .opened, author: "me")

        let current = map(request, local: .current)
        let worktree = map(request, local: .worktree(path: "/wt/x"))
        let local = map(request, local: .local)
        let dirty = map(request, local: .local, isMainCheckoutClean: false)
        let none = map(request, local: .none)

        #expect(current.tags.map(\.text) == ["current"])
        #expect(current.canCreateWorktree == false)
        #expect(current.canSwitchBranch == false)
        #expect(worktree.tags.map(\.text) == ["worktree"])
        #expect(worktree.worktreePath == "/wt/x")
        #expect(worktree.canCreateWorktree == false)
        #expect(local.tags.map(\.text) == ["local"])
        #expect(local.tags.map(\.tint) == [.teal])
        #expect(local.canSwitchBranch)
        #expect(local.canCreateWorktree)
        #expect(dirty.canSwitchBranch == false)
        #expect(none.tags.isEmpty)
        #expect(none.canCreateWorktree)
        #expect(none.worktreePath == nil)
    }

    @Test func aFinishedRequestShowsNoLocalState() {
        let request = PullRequestSummaryFixture.request(iid: 7, source: "x", state: .merged)

        let model = map(request, local: .local)

        #expect(model.tags == [TagModel("merged", tint: .purple)])
        #expect(model.canSwitchBranch == false)
        #expect(model.canCreateWorktree == false)
    }

    @Test func theTicketComesFromTheTitleAndTheLinkTextIsReady() {
        let request = PullRequestSummaryFixture.request(iid: 7, source: "feature/ABC-9-x", state: .opened, title: "Fix the crash")

        let model = map(request)

        #expect(model.ticket == TicketModel(key: "ABC-9", url: URL(string: "https://jira.example.com/browse/ABC-9"), hint: "Open ABC-9 in the tracker"))
        #expect(model.linkText == "!7 Fix the crash\nhttps://gitlab.example.com/team/app/-/merge_requests/7")
        #expect(map(PullRequestSummaryFixture.request(iid: 7, source: "x", state: .opened)).ticket?.key == "ABC-5")
    }

    private func map(
        _ request: PullRequestSummary,
        username: String? = "me",
        scope: PullRequestScope = .all,
        seenAt: Date? = nil,
        local: PullRequestLocalState = .none,
        isMainCheckoutClean: Bool = true,
        isBusy: Bool = false,
        isExpanded: Bool = false
    ) -> PullRequestRowModel {
        PullRequestRowMapper.model(
            for: request,
            context: PullRequestRowContext(username: username, scope: scope, seenAt: seenAt, now: now, isMainCheckoutClean: isMainCheckoutClean, ticket: .linking("https://jira.example.com/browse/{key}"), words: .gitLab, staleDays: 14),
            local: local,
            isBusy: isBusy,
            isExpanded: isExpanded
        )
    }
}
