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
}
