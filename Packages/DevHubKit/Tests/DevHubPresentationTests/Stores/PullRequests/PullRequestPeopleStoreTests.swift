import Foundation
import Testing
import DevHubDomain
import DevHubTestSupport
@testable import DevHubPresentation

@Suite struct PullRequestPeopleStoreTests {
    private let harness = StoreHarness()
    private let remote = CodeHost.gitLabSample

    private var store: PullRequestPeopleStore {
        harness.pullRequestPeople
    }

    private var request: PullRequestSummary {
        PullRequestSummaryFixture.request(iid: 7, source: "x", state: .opened, assignees: ["alex"], reviewers: ["sam"])
    }

    @Test func peopleAreReadOncePerProject() async {
        harness.spies.git.webURLResult = remote.webURL
        harness.spies.codeHost.peopleResult = .success(["alex", "sam"])

        await store.loadIfNeeded()
        await store.loadIfNeeded()

        #expect(store.people == ["alex", "sam"])
        #expect(harness.spies.codeHost.calls == [.people(repository: remote)])
    }

    @Test func aFailedReadIsLoggedAndTriedAgainLater() async {
        harness.spies.git.webURLResult = remote.webURL
        harness.spies.codeHost.peopleResult = .failure(PullRequestError.command("boom"))

        await store.loadIfNeeded()
        await store.loadIfNeeded()

        #expect(store.people.isEmpty)
        #expect(harness.lastActivity?.title == "Cannot read the people of this project")
        #expect(harness.spies.codeHost.calls.count == 2)
    }

    @Test func aProjectChangeForgetsThePeople() async {
        harness.spies.git.webURLResult = remote.webURL
        harness.spies.codeHost.peopleResult = .success(["alex"])
        await store.loadIfNeeded()

        harness.events.post(.projectChanged)

        #expect(store.people.isEmpty)
    }

    @Test func togglingANewReviewerAddsThemAndRefreshesTheList() async throws {
        harness.spies.git.webURLResult = remote.webURL
        _ = try await harness.codeHostRemote.codeHost()

        store.toggle("kim", role: .reviewer, on: request)
        #expect(store.busyIDs == [7])

        try await waitUntil { store.busyIDs.isEmpty }
        #expect(harness.spies.codeHost.calls.contains(.updatePeople(iid: 7, role: .reviewer, add: ["kim"], remove: [], repository: remote)))
        #expect(harness.operations.latest(at: .pullRequest(7))?.title == "Request review from kim on !7")
        #expect(harness.postedLabels.contains("refreshRequested(pullRequests)"))
    }

    @Test func togglingACurrentAssigneeRemovesThem() async throws {
        harness.spies.git.webURLResult = remote.webURL
        _ = try await harness.codeHostRemote.codeHost()

        store.toggle("alex", role: .assignee, on: request)

        try await waitUntil { store.busyIDs.isEmpty }
        #expect(harness.spies.codeHost.calls.contains(.updatePeople(iid: 7, role: .assignee, add: [], remove: ["alex"], repository: remote)))
        #expect(harness.lastActivity?.title == "Unassign alex from !7")
    }

    @Test func aFailedChangeFailsTheOperation() async throws {
        harness.spies.git.webURLResult = remote.webURL
        _ = try await harness.codeHostRemote.codeHost()
        harness.spies.codeHost.actionError = PullRequestError.command("not allowed")

        store.toggle("sam", role: .reviewer, on: request)

        try await waitUntil { store.busyIDs.isEmpty }
        #expect(harness.operations.latest(at: .pullRequest(7))?.failureMessage == "not allowed")
        #expect(harness.lastActivity?.title == "Remove sam as reviewer of !7 failed")
        #expect(harness.postedLabels.contains("refreshRequested(pullRequests)") == false)
    }
}
