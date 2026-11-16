import Foundation
import Testing
import DevHubDomain
import DevHubTestSupport
@testable import DevHubPresentation

@Suite struct InboxStoreTests {
    private let harness = StoreHarness()
    private let remote = CodeHost.gitLabSample
    private let mention = InboxItem(id: "701", kind: .mention, title: "ABC-123: Login screen", actor: "sam", excerpt: "@alex check the retry path", target: .pullRequest(iid: 12), webURL: nil, updatedAt: nil)
    private let assigned = InboxItem(id: "703", kind: .assigned, title: "Crash on cold start", actor: "lee", excerpt: nil, target: .issue(iid: 31), webURL: nil, updatedAt: nil)

    private var store: InboxStore {
        harness.inbox
    }

    private func script(_ items: [InboxItem]) {
        harness.spies.git.webURLResult = remote.webURL
        harness.spies.codeHost.inboxResult = .success(items)
    }

    @Test func refreshLoadsTheItemsOfTheRepository() async {
        script([mention, assigned])

        await store.refresh()

        #expect(store.items == [mention, assigned])
        #expect(store.unreadCount == 2)
        #expect(store.error == nil)
        #expect(store.isLoading == false)
        #expect(harness.spies.codeHost.calls == [.inbox(repository: remote)])
    }

    @Test func theFirstLoadIsSilentAndANewItemIsReportedAndNotified() async throws {
        script([assigned])
        await store.refresh()
        await harness.settle()
        #expect(harness.activityTitles.isEmpty)
        script([mention, assigned])

        await store.refresh()

        #expect(harness.lastActivity?.title == "sam mentioned you in !12")
        #expect(harness.lastActivity?.detail == "@alex check the retry path")
        #expect(harness.lastActivity?.kind == .inbox)
        #expect(harness.lastActivity?.target == .pullRequest(iid: 12))
        try await waitUntil { harness.spies.notifications.posted == [.post(title: "sam mentioned you in !12", body: "@alex check the retry path", target: .pullRequest(iid: 12))] }
    }

    @Test func anItemWithoutARequestOpensTheInbox() async {
        script([])
        await store.refresh()
        script([assigned])

        await store.refresh()

        #expect(harness.lastActivity?.title == "lee assigned you issue #31")
        #expect(harness.lastActivity?.target == .inbox)
    }

    @Test func markDoneCallsTheHostAndDropsTheItem() async throws {
        script([mention, assigned])
        await store.refresh()

        store.markDone("701")

        #expect(store.busyIDs == ["701"])
        try await waitUntil { store.items == [assigned] }
        #expect(store.busyIDs.isEmpty)
        #expect(harness.spies.codeHost.calls.last == .markInboxDone(id: "701", repository: remote))
    }

    @Test func markAllDoneMarksEveryItem() async throws {
        script([mention, assigned])
        await store.refresh()

        store.markAllDone()

        try await waitUntil { store.items.isEmpty }
        #expect(harness.spies.codeHost.calls.contains(.markInboxDone(id: "701", repository: remote)))
        #expect(harness.spies.codeHost.calls.contains(.markInboxDone(id: "703", repository: remote)))
    }

    @Test func aFailedMarkDoneIsLoggedAndKeepsTheItem() async throws {
        script([mention])
        await store.refresh()
        harness.spies.codeHost.actionError = PullRequestError.command("boom")

        store.markDone("701")

        try await waitUntil { harness.lastActivity?.title == "Could not mark !12 as done" }
        #expect(harness.lastActivity?.outcome == .failure)
        #expect(store.items == [mention])
        #expect(store.busyIDs.isEmpty)
    }

    @Test func aFailureIsLoggedOnceAndShown() async {
        harness.spies.git.webURLResult = remote.webURL
        harness.spies.codeHost.inboxResult = .failure(PullRequestError.command("boom"))

        await store.refresh()
        await store.refresh()

        #expect(store.error != nil)
        #expect(harness.activityTitles == ["Cannot read the Inbox of GitLab"])
    }

    @Test func noCodeHostIsSilent() async {
        await store.refresh()

        #expect(store.error == nil)
        #expect(harness.activityTitles.isEmpty)
    }

    @Test func projectChangedClearsAndReloads() async throws {
        script([mention])
        await store.refresh()
        harness.spies.codeHost.inboxResult = .success([])

        harness.events.post(.projectChanged)

        #expect(store.items.isEmpty)
        try await waitUntil { harness.spies.codeHost.calls.count == 2 }
    }

    @Test func refreshIfStaleLoadsOnce() async {
        script([mention])

        await store.refreshIfStale()
        await store.refreshIfStale()

        #expect(harness.spies.codeHost.calls.count == 1)
    }

    @Test func showSwitchesThePane() {
        #expect(store.pane == .events)

        store.showInbox()
        #expect(store.pane == .inbox)

        store.show(.events)
        #expect(store.pane == .events)
    }
}
