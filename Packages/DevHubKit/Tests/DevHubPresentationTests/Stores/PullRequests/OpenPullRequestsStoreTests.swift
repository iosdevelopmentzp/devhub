import Foundation
import Testing
import DevHubDomain
import DevHubTestSupport
@testable import DevHubPresentation

@Suite struct OpenPullRequestsStoreTests {
    private let harness = StoreHarness()
    private let remote = CodeHost.gitLabSample

    private var store: OpenPullRequestsStore {
        harness.openPullRequests
    }

    private func script(_ requests: [PullRequestSummary]) {
        harness.spies.git.webURLResult = remote.webURL
        harness.spies.codeHost.openRequestsResult = .success(PullRequestList(username: "me", requests: requests, totalCount: requests.count))
    }

    @Test func requestsAreFoundByBranchAndCountedForReview() async {
        let mine = PullRequestSummaryFixture.request(iid: 1, source: "feature/mine", state: .opened, author: "me")
        script([PullRequestSummaryFixture.open, mine])

        await store.refresh()

        #expect(store.request(forBranch: "feature/login") == PullRequestSummaryFixture.open)
        #expect(store.request(forBranch: "origin/feature/login") == PullRequestSummaryFixture.open)
        #expect(store.request(forBranch: "feature/mine") == mine)
        #expect(store.request(forBranch: "dev") == nil)
        #expect(store.reviewCount == 1)
        #expect(store.username == "me")
        #expect(harness.spies.codeHost.calls == [.openRequests(repository: remote)])
    }

    @Test func moreRequestsForReviewNotifyAfterTheFirstLoad() async throws {
        script([])
        await store.refresh()
        script([PullRequestSummaryFixture.open])

        await store.refresh()

        try await waitUntil { harness.spies.notifications.posted == [.post(title: "1 merge request waits for your review", body: nil, target: .reviewQueue)] }
    }

    @Test func refreshIfStaleLoadsOnce() async {
        script([PullRequestSummaryFixture.open])

        await store.refreshIfStale()
        await store.refreshIfStale()

        #expect(harness.spies.codeHost.calls == [.openRequests(repository: remote)])
    }

    @Test func aFailureKeepsTheLastValues() async {
        script([PullRequestSummaryFixture.open])
        await store.refresh()
        harness.spies.codeHost.openRequestsResult = .failure(PullRequestError.notInstalled(tool: "glab"))

        await store.refresh()

        #expect(store.reviewCount == 1)
        #expect(store.username == "me")
        #expect(store.request(forBranch: "feature/login") != nil)
    }

    @Test func aFailureIsLoggedOnceAndNotGitLabIsSilent() async {
        await store.refresh()
        #expect(harness.activityTitles.isEmpty)

        harness.spies.git.webURLResult = remote.webURL
        harness.spies.codeHost.openRequestsResult = .failure(PullRequestError.command("boom"))
        await store.refresh()
        await store.refresh()

        #expect(harness.activityTitles == ["Cannot read open merge requests"])
    }

    @Test func moreThanTheReadPageIsReportedOnce() async {
        harness.spies.git.webURLResult = remote.webURL
        harness.spies.codeHost.openRequestsResult = .success(PullRequestList(username: "me", requests: [PullRequestSummaryFixture.open], totalCount: 120))

        await store.refresh()
        await store.refresh()

        #expect(harness.activityTitles == ["GitLab has 120 open merge requests, DevHub reads 1"])
        #expect(harness.activity.events.first?.outcome == .info)
    }

    @Test func pullRequestsChangedReloads() async throws {
        script([PullRequestSummaryFixture.open])
        await store.refresh()

        harness.events.post(.pullRequestsChanged)

        try await waitUntil { harness.spies.codeHost.calls.count == 2 }
    }

    @Test func projectChangedClearsAndReloads() async throws {
        script([PullRequestSummaryFixture.open])
        await store.refresh()
        harness.spies.codeHost.openRequestsResult = .success(PullRequestList(username: "me", requests: [], totalCount: 0))

        harness.events.post(.projectChanged)

        #expect(store.requestsByBranch.isEmpty)
        #expect(store.reviewCount == 0)
        try await waitUntil { harness.spies.codeHost.calls.count == 2 }
    }

    @Test func aConfigActionCanAskForARefresh() async throws {
        script([PullRequestSummaryFixture.open])
        await store.refresh()

        harness.events.post(.refreshRequested(.pullRequests))

        try await waitUntil { harness.spies.codeHost.calls.count == 2 }
    }

    // MARK: Changes of my requests

    private func mine(approvedBy: [String] = [], pipeline: PipelineInfo? = nil, comments: Int = 0) -> PullRequestSummary {
        PullRequestSummaryFixture.request(iid: 7, source: "feature/mine", state: .opened, author: "me", comments: comments, pipeline: pipeline, approvedBy: approvedBy, title: "ABC-7: Mine")
    }

    @Test func anApprovalOfMyRequestIsReportedAndNotified() async throws {
        script([mine()])
        await store.refresh()
        script([mine(approvedBy: ["alex"])])

        await store.refresh()

        #expect(harness.lastActivity?.title == "!7 approved by alex")
        #expect(harness.lastActivity?.detail == "ABC-7: Mine")
        #expect(harness.lastActivity?.outcome == .success)
        try await waitUntil { harness.spies.notifications.posted == [.post(title: "!7 approved by alex", body: "ABC-7: Mine", target: .pullRequest(iid: 7))] }
    }

    @Test func theFirstLoadReportsNothing() async {
        script([mine(approvedBy: ["alex"], pipeline: PipelineInfo(status: .failed, webURL: nil, updatedAt: nil), comments: 4)])

        await store.refresh()
        await harness.settle()

        #expect(harness.activityTitles.isEmpty)
        #expect(harness.spies.notifications.posted.isEmpty)
    }

    @Test func failedChecksAndNewCommentsAreReported() async {
        script([mine(comments: 1)])
        await store.refresh()
        script([mine(pipeline: PipelineInfo(status: .failed, webURL: nil, updatedAt: nil), comments: 3)])

        await store.refresh()

        #expect(harness.activityTitles == ["2 new comments on !7", "Pipeline failed on !7"])
        #expect(harness.activity.events.last?.outcome == .failure)
    }

    @Test func aRefreshAfterMyOwnActionUpdatesTheBaselineWithoutAReport() async throws {
        script([mine(comments: 1)])
        await store.refresh()
        script([mine(comments: 2)])

        harness.events.post(.pullRequestsChanged)
        try await waitUntil { store.request(forBranch: "feature/mine")?.commentCount == 2 }
        await store.refresh()

        #expect(harness.spies.codeHost.calls.count == 3)
        #expect(harness.activityTitles.isEmpty)
    }

    @Test func aMergedRequestIsReportedAfterAStatusRead() async throws {
        script([mine()])
        await store.refresh()
        script([])
        harness.spies.codeHost.statusResult = .success(PullRequestStatus(pullRequest: info(state: .merged), pipeline: nil))

        await store.refresh()

        try await waitUntil { harness.activityTitles == ["!7 merged"] }
        #expect(harness.spies.codeHost.calls.last == .status(branch: "feature/mine", repository: remote))
        try await waitUntil { harness.spies.notifications.posted == [.post(title: "!7 merged", body: "ABC-7: Mine", target: .pullRequest(iid: 7))] }
    }

    @Test func aRequestThatIsStillOpenAfterLeavingTheListIsSilent() async throws {
        script([mine()])
        await store.refresh()
        script([])
        harness.spies.codeHost.statusResult = .success(PullRequestStatus(pullRequest: info(state: .opened), pipeline: nil))

        await store.refresh()

        try await waitUntil { harness.spies.codeHost.calls.count == 3 }
        await harness.settle()
        #expect(harness.activityTitles.isEmpty)
    }

    @Test func theSettingStopsTheNotificationButNotTheRecentRow() async throws {
        harness.settings.values.setNotifies(.requestReviews, false)
        script([mine()])
        await store.refresh()
        script([mine(approvedBy: ["alex"])])

        await store.refresh()
        await harness.settle()

        #expect(harness.activityTitles == ["!7 approved by alex"])
        #expect(harness.spies.notifications.posted.isEmpty)
    }

    private func info(state: PullRequestState) -> PullRequestInfo {
        PullRequestInfo(iid: 7, title: "ABC-7: Mine", state: state, isDraft: false, webURL: nil, author: "me", hasConflicts: false, detailedStatus: nil, targetBranch: "dev")
    }
}
