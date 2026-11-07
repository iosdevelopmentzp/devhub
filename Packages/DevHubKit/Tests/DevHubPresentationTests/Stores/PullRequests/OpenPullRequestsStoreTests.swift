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

    private func mine(approvedBy: [String] = [], pipeline: PipelineInfo? = nil, comments: Int = 0, recent: [RecentComment] = []) -> PullRequestSummary {
        PullRequestSummaryFixture.request(iid: 7, source: "feature/mine", state: .opened, author: "me", comments: comments, pipeline: pipeline, approvedBy: approvedBy, recentComments: recent, title: "ABC-7: Mine")
    }

    @Test func aCommentBySomeoneElseNamesTheAuthor() async throws {
        script([mine(comments: 1, recent: [RecentComment(id: "1", author: "me")])])
        await store.refresh()
        script([mine(comments: 2, recent: [RecentComment(id: "1", author: "me"), RecentComment(id: "2", author: "sam")])])

        await store.refresh()

        try await waitUntil { harness.activityTitles == ["sam commented on !7"] }
        try await waitUntil { harness.spies.notifications.posted == [.post(title: "sam commented on !7", body: "ABC-7: Mine", target: .pullRequest(iid: 7))] }
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

    // MARK: Watched requests

    private func theirs(approvedBy: [String] = []) -> PullRequestSummary {
        PullRequestSummaryFixture.request(iid: 12, source: "feature/theirs", state: .opened, author: "sam", approvedBy: approvedBy, title: "ABC-12: Theirs")
    }

    @Test func toggleWatchPersistsPerProject() {
        #expect(store.toggleWatch(iid: 12))
        #expect(store.watchedIDs == [12])
        #expect(store.isWatched(12))
        #expect(harness.store.decode([Int].self, forKey: "gitlab.watched.\(harness.session.selectedProjectID)") == [12])

        #expect(store.toggleWatch(iid: 12) == false)
        #expect(store.watchedIDs.isEmpty)
        #expect(harness.store.decode([Int].self, forKey: "gitlab.watched.\(harness.session.selectedProjectID)") == [])
    }

    @Test func aWatchedRequestOfSomeoneElseReportsWithTheWatchedKind() async throws {
        script([theirs()])
        await store.refresh()
        _ = store.toggleWatch(iid: 12)
        script([theirs(approvedBy: ["lee"])])

        await store.refresh()

        #expect(harness.lastActivity?.title == "!12 approved by lee")
        #expect(harness.lastActivity?.kind == .watched)
        #expect(harness.lastActivity?.target == .pullRequest(iid: 12))
        try await waitUntil { harness.spies.notifications.posted == [.post(title: "!12 approved by lee", body: "ABC-12: Theirs", target: .pullRequest(iid: 12))] }
    }

    @Test func aRequestOfSomeoneElseThatIsNotWatchedIsSilent() async {
        script([theirs()])
        await store.refresh()
        script([theirs(approvedBy: ["lee"])])

        await store.refresh()
        await harness.settle()

        #expect(harness.activityTitles.isEmpty)
    }

    @Test func aMergedWatchedRequestIsReportedAndForgotten() async throws {
        script([theirs()])
        await store.refresh()
        _ = store.toggleWatch(iid: 12)
        script([])
        harness.spies.codeHost.statusResult = .success(PullRequestStatus(pullRequest: PullRequestInfo(iid: 12, title: "ABC-12: Theirs", state: .merged, isDraft: false, webURL: nil, author: "sam", hasConflicts: false, detailedStatus: nil, targetBranch: "dev"), pipeline: nil))

        await store.refresh()

        try await waitUntil { harness.activityTitles == ["!12 merged"] }
        #expect(harness.lastActivity?.kind == .watched)
        #expect(store.watchedIDs.isEmpty)
    }

    @Test func projectChangedLoadsTheWatchedIDsOfTheProject() {
        _ = store
        harness.store.encode([3, 4], forKey: "gitlab.watched.\(harness.session.selectedProjectID)")

        harness.events.post(.projectChanged)

        #expect(store.watchedIDs == [3, 4])
    }

    @Test func thePollIntervalIsShorterWhileThePanelIsClosedOrARequestIsWatched() {
        #expect(OpenPullRequestsStore.pollInterval(panelShown: true, watching: false) == .seconds(300))
        #expect(OpenPullRequestsStore.pollInterval(panelShown: false, watching: false) == .seconds(120))
        #expect(OpenPullRequestsStore.pollInterval(panelShown: true, watching: true) == .seconds(60))
        #expect(OpenPullRequestsStore.pollInterval(panelShown: false, watching: true) == .seconds(60))
    }

    private func useReviewQueue(_ value: String) async {
        let config = ProjectConfig(git: GitConfig(pullRequests: PullRequestsConfig(reviewQueue: value)))
        harness.spies.config.loadResult = ResolvedConfig(project: config, actions: [], tabs: [], issues: [], layers: [])
        await harness.config.reload()
    }

    @Test func theAssignedRuleCountsRequestsForMeOrMyTeamsOnly() async {
        await useReviewQueue("assigned")
        harness.spies.codeHost.myTeamsResult = .success(["example/ios"])
        script([
            PullRequestSummaryFixture.request(iid: 1, source: "a", state: .opened),
            PullRequestSummaryFixture.request(iid: 2, source: "b", state: .opened, reviewers: ["me"]),
            PullRequestSummaryFixture.request(iid: 3, source: "c", state: .opened, requestedTeams: ["example/ios"]),
            PullRequestSummaryFixture.request(iid: 4, source: "d", state: .opened, requestedTeams: ["example/qa"]),
        ])

        await store.refresh()
        await store.refresh()

        #expect(store.reviewQueue == .assigned)
        #expect(store.reviewTeams == ["example/ios"])
        #expect(store.reviewCount == 2)
        #expect(harness.spies.codeHost.calls.filter { $0 == .myTeams(repository: remote) }.count == 1)
    }

    @Test func theOpenRuleNeverReadsTheTeams() async {
        script([PullRequestSummaryFixture.request(iid: 1, source: "a", state: .opened, requestedTeams: ["example/qa"])])

        await store.refresh()

        #expect(store.reviewQueue == .open)
        #expect(store.reviewCount == 1)
        #expect(harness.spies.codeHost.calls == [.openRequests(repository: remote)])
    }

    @Test func aFailedTeamsReadIsLoggedOnceAndCountsMyOwnRequests() async {
        await useReviewQueue("assigned")
        harness.spies.codeHost.myTeamsResult = .failure(PullRequestError.command("no read:org"))
        script([
            PullRequestSummaryFixture.request(iid: 1, source: "a", state: .opened, assignees: ["me"]),
            PullRequestSummaryFixture.request(iid: 2, source: "b", state: .opened, requestedTeams: ["example/ios"]),
        ])

        await store.refresh()
        await store.refresh()

        #expect(store.reviewCount == 1)
        #expect(harness.activityTitles.filter { $0 == "Cannot read your teams on GitLab" }.count == 1)
    }

    @Test func aChangeOfTheRuleCountsAgainWithoutANotice() async throws {
        await useReviewQueue("assigned")
        script([
            PullRequestSummaryFixture.request(iid: 1, source: "a", state: .opened, reviewers: ["me"]),
            PullRequestSummaryFixture.request(iid: 2, source: "b", state: .opened),
        ])
        await store.refresh()
        #expect(store.reviewCount == 1)

        await useReviewQueue("open")

        try await waitUntil { store.reviewCount == 2 }
        #expect(harness.spies.notifications.posted.isEmpty)
    }

    @Test func aRequestThatWaitsTooLongForMyReviewIsRemindedOnce() async throws {
        let key = "gitlab.reviewSince.\(harness.session.selectedProjectID)"
        harness.store.encode([ReviewWait(iid: 21, since: Date(timeIntervalSinceNow: -5 * 3_600), isReminded: false)], forKey: key)
        script([PullRequestSummaryFixture.open, PullRequestSummaryFixture.request(iid: 22, source: "b", state: .opened)])

        await store.refresh()
        await store.refresh()

        let reminder = SpyUserNotificationRepository.Call.post(title: "!21 waits for your review for 5 h", body: "ABC-5: Login", target: .pullRequest(iid: 21))
        try await waitUntil { harness.spies.notifications.posted.contains(reminder) }
        #expect(harness.spies.notifications.posted.filter { $0 == reminder }.count == 1)
        #expect(harness.activityTitles.filter { $0.hasSuffix("waits for your review for 5 h") } == ["!21 waits for your review for 5 h"])
        let waits = try #require(harness.store.decode([ReviewWait].self, forKey: key))
        #expect(waits.map(\.iid) == [21, 22])
        #expect(waits.map(\.isReminded) == [true, false])
    }

    @Test func aRequestThatLeavesTheQueueForgetsItsWait() async throws {
        let key = "gitlab.reviewSince.\(harness.session.selectedProjectID)"
        script([PullRequestSummaryFixture.open])
        await store.refresh()
        #expect(harness.store.decode([ReviewWait].self, forKey: key)?.map(\.iid) == [21])

        script([])
        await store.refresh()

        #expect(harness.store.decode([ReviewWait].self, forKey: key) == [])
    }

    @Test func noReminderWhenTheSettingIsOff() async {
        harness.settings.values.reviewReminderHours = 0
        harness.store.encode([ReviewWait(iid: 21, since: Date(timeIntervalSinceNow: -50 * 3_600), isReminded: false)], forKey: "gitlab.reviewSince.\(harness.session.selectedProjectID)")
        script([PullRequestSummaryFixture.open])

        await store.refresh()

        #expect(harness.activityTitles.contains { $0.contains("waits for your review for") } == false)
    }
}
