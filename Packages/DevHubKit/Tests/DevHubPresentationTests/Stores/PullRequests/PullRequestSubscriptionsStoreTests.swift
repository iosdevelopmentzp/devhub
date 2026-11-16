import Foundation
import Testing
import DevHubDomain
import DevHubTestSupport
@testable import DevHubPresentation

@Suite struct PullRequestSubscriptionsStoreTests {
    private let harness = StoreHarness()
    private let remote = CodeHost.gitLabSample

    private var store: PullRequestSubscriptionsStore {
        harness.pullRequestSubscriptions
    }

    private var savedKey: String {
        "gitlab.unsubscribed.\(harness.session.selectedProjectID)"
    }

    private func theirs(_ iid: Int, subscribed: Bool?) -> PullRequestSummary {
        PullRequestSummaryFixture.request(iid: iid, source: "feature/\(iid)", state: .opened, isSubscribed: subscribed)
    }

    private func load(_ requests: [PullRequestSummary]) async {
        harness.spies.git.webURLResult = remote.webURL
        harness.spies.codeHost.openRequestsResult = .success(PullRequestList(username: "me", requests: requests, totalCount: requests.count))
        await harness.openPullRequests.refresh()
    }

    @Test func unsubscribingOneRequestCallsTheHostAndRemembersIt() async {
        let request = theirs(12, subscribed: true)
        harness.spies.git.webURLResult = remote.webURL

        #expect(await store.set(false, for: request))

        #expect(harness.spies.codeHost.calls == [.setSubscribed(false, iids: [12], repository: remote)])
        #expect(store.changes == [12: false])
        #expect(store.unsubscribedIDs == [12])
        #expect(harness.store.decode([Int].self, forKey: savedKey) == [12])
        #expect(store.busyIDs.isEmpty)
        #expect(harness.lastActivity?.title == "Unsubscribed from !12 on GitLab")
        #expect(harness.lastActivity?.outcome == .success)
    }

    @Test func subscribingAgainForgetsTheSavedID() async {
        harness.spies.git.webURLResult = remote.webURL
        _ = await store.set(false, for: theirs(12, subscribed: true))

        #expect(await store.set(true, for: theirs(12, subscribed: false)))

        #expect(store.changes == [12: true])
        #expect(store.unsubscribedIDs.isEmpty)
        #expect(harness.store.decode([Int].self, forKey: savedKey) == [])
    }

    @Test func aFailureIsLoggedAndChangesNothing() async {
        harness.spies.git.webURLResult = remote.webURL
        harness.spies.codeHost.actionError = PullRequestError.missingScope(tool: "gh", host: "github.com", scope: "notifications")

        #expect(await store.set(false, for: theirs(12, subscribed: true)) == false)

        #expect(store.changes.isEmpty)
        #expect(store.unsubscribedIDs.isEmpty)
        #expect(harness.lastActivity?.title == "Could not unsubscribe from !12")
        #expect(harness.lastActivity?.detail == "The gh login has no notifications scope. Run gh auth refresh --hostname github.com --scopes notifications")
        #expect(harness.lastActivity?.outcome == .failure)
    }

    @Test func unsubscribeOthersSendsOnlySubscribedOpenRequestsOfOtherPeopleInOneCall() async {
        let mine = PullRequestSummaryFixture.request(iid: 1, source: "feature/mine", state: .opened, author: "me", isSubscribed: true)
        await load([mine, theirs(12, subscribed: true), theirs(13, subscribed: false), theirs(14, subscribed: true)])
        #expect(store.othersToUnsubscribe.map(\.iid) == [12, 14])

        #expect(await store.unsubscribeOthers() == 2)

        #expect(harness.spies.codeHost.calls.last == .setSubscribed(false, iids: [12, 14], repository: remote))
        #expect(store.othersToUnsubscribe.isEmpty)
        #expect(store.unsubscribedIDs == [12, 14])
        #expect(store.toSubscribeAgain.map(\.iid) == [12, 14])
        #expect(store.isBulkRunning == false)
        #expect(harness.lastActivity?.title == "Unsubscribed from 2 merge requests on GitLab")
    }

    @Test func unsubscribeOthersWithNothingToDoCallsNothing() async {
        await load([theirs(13, subscribed: false)])

        #expect(await store.unsubscribeOthers() == nil)

        #expect(harness.spies.codeHost.calls == [.openRequests(repository: remote)])
    }

    @Test func subscribeAgainRestoresOnlyWhatDevHubUnsubscribed() async {
        await load([theirs(12, subscribed: true), theirs(13, subscribed: false)])
        _ = await store.unsubscribeOthers()

        #expect(await store.subscribeAgain() == 1)

        #expect(harness.spies.codeHost.calls.last == .setSubscribed(true, iids: [12], repository: remote))
        #expect(store.unsubscribedIDs.isEmpty)
        #expect(store.toSubscribeAgain.isEmpty)
        #expect(store.othersToUnsubscribe.map(\.iid) == [12])
    }

    @Test func aRefreshRequestDropsTheChangesAndTheProjectReloadsTheSavedIDs() async {
        harness.spies.git.webURLResult = remote.webURL
        _ = await store.set(false, for: theirs(12, subscribed: true))
        harness.events.post(.refreshRequested(.pullRequests))
        #expect(store.changes.isEmpty)
        #expect(store.unsubscribedIDs == [12])

        harness.store.encode([5], forKey: savedKey)
        harness.events.post(.projectChanged)

        #expect(store.unsubscribedIDs == [5])
    }
}
