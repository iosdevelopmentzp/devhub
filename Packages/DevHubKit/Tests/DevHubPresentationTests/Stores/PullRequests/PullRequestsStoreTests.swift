import Foundation
import Testing
import DevHubDomain
import DevHubMocks
import DevHubTestSupport
@testable import DevHubPresentation

@Suite struct PullRequestsStoreTests {
    private let harness = StoreHarness()
    private let remote = CodeHost.gitLabSample

    private var store: PullRequestsStore {
        harness.pullRequests
    }

    private func script(_ requests: [PullRequestSummary], username: String = "me") {
        harness.spies.git.webURLResult = remote.webURL
        harness.spies.codeHost.listResult = .success(PullRequestList(username: username, requests: requests, totalCount: requests.count))
    }

    @Test func filtersDefaultToMyOpenRequestsAndArePersisted() {
        #expect(store.query == PullRequestQuery(scope: .mine, state: .opened))
        #expect(store.filter == PullRequestFilter())

        store.scope = .assigned
        store.stateFilter = .merged
        store.filter = PullRequestFilter(label: "tech", onlyConflicts: true)

        #expect(harness.store.string(forKey: "gitlab.scope") == "assigned")
        #expect(harness.store.string(forKey: "gitlab.state") == "merged")
        let restored = StoreHarness(store: harness.store).pullRequests
        #expect(restored.query == PullRequestQuery(scope: .assigned, state: .merged))
        #expect(restored.filter == PullRequestFilter(label: "tech", onlyConflicts: true))
    }

    @Test func listStyleStartsDetailedAndIsRemembered() {
        #expect(store.listStyle == .detailed)

        store.listStyle = .compact

        #expect(harness.store.string(forKey: "gitlab.listStyle") == "compact")
        #expect(StoreHarness(store: harness.store).pullRequests.listStyle == .compact)
    }

    @Test func listWidthStartsAt42PercentAndIsRemembered() {
        #expect(store.listFraction == 0.42)

        store.listFraction = 0.5

        #expect(StoreHarness(store: harness.store).pullRequests.listFraction == 0.5)
    }

    @Test func reviewingAlwaysAsksForOpenRequests() {
        store.stateFilter = .merged
        store.scope = .reviewing

        #expect(store.query == PullRequestQuery(scope: .reviewing, state: .opened))
    }

    @Test func refreshLoadsTheListForTheQuery() async {
        script([PullRequestSummaryFixture.open])

        await store.refresh()

        #expect(store.requests == [PullRequestSummaryFixture.open])
        #expect(store.username == "me")
        #expect(store.hasLoaded)
        #expect(store.error == nil)
        #expect(store.isLoading == false)
        #expect(harness.spies.codeHost.calls == [.list(PullRequestQuery(scope: .mine, state: .opened), after: nil, repository: remote)])
    }

    @Test func withoutARemoteTheErrorIsNotGitLab() async {
        await store.refresh()

        #expect(store.error == .noCodeHost)
        #expect(harness.spies.codeHost.calls.isEmpty)
        #expect(harness.activityTitles.isEmpty)
    }

    @Test func refreshIfStaleLoadsOnceAndAgainAfterAQueryChange() async {
        script([PullRequestSummaryFixture.open])

        await store.refreshIfStale()
        await store.refreshIfStale()
        #expect(harness.spies.codeHost.calls.count == 1)

        store.stateFilter = .merged
        await store.refreshIfStale()
        #expect(harness.spies.codeHost.calls.count == 2)
    }

    @Test func aFailureIsLoggedOnceUntilItChanges() async {
        script([PullRequestSummaryFixture.open])
        await store.refresh()
        harness.spies.codeHost.listResult = .failure(PullRequestError.command("boom"))

        await store.refresh()
        await store.refresh()
        #expect(store.requests == [PullRequestSummaryFixture.open])
        #expect(store.error == .command("boom"))
        #expect(harness.activityTitles == ["Cannot read merge requests"])

        harness.spies.codeHost.listResult = .failure(PullRequestError.command("other"))
        await store.refresh()
        #expect(harness.activityTitles.count == 2)

        await store.refreshIfStale()
        #expect(harness.spies.codeHost.calls.count == 5)
    }

    @Test func aFailureKeepsTheErrorAndAChangedQueryClearsTheList() async {
        script([PullRequestSummaryFixture.open])
        await store.refresh()

        store.stateFilter = .all
        #expect(store.hasLoaded == false)
        harness.spies.codeHost.listResult = .failure(PullRequestError.notLoggedIn(tool: "glab", host: "gitlab.example.com"))
        await store.refresh()

        #expect(store.requests.isEmpty)
        #expect(store.error == .notLoggedIn(tool: "glab", host: "gitlab.example.com"))
        #expect(store.hasLoaded)
    }

    @Test func visibleAppliesTheReviewQueueAndTheFilter() async {
        let mine = PullRequestSummaryFixture.request(iid: 1, source: "a", state: .opened, author: "me", labels: ["tech"])
        let other = PullRequestSummaryFixture.request(iid: 2, source: "b", state: .opened, labels: ["tech"])
        let approved = PullRequestSummaryFixture.request(iid: 3, source: "c", state: .opened, approvedBy: ["me"], target: "main")
        script([mine, other, approved])
        await store.refresh()

        #expect(store.visible.map(\.iid) == [1, 2, 3])
        #expect(store.filterOptions == PullRequestFilterOptions(targetBranches: ["dev", "main"], labels: ["tech"]))

        store.filter = PullRequestFilter(label: "tech")
        #expect(store.visible.map(\.iid) == [1, 2])

        store.scope = .reviewing
        await store.refresh()
        #expect(store.visible.map(\.iid) == [2])
    }

    @Test func removeFilterClearsOnePartAndClearFilterClearsAll() {
        store.filter = PullRequestFilter(targetBranch: "dev", label: "tech", onlyConflicts: true, onlyReady: true)

        store.removeFilter(.label)
        #expect(store.filter == PullRequestFilter(targetBranch: "dev", onlyConflicts: true, onlyReady: true))
        store.removeFilter(.targetBranch)
        store.removeFilter(.onlyReady)
        #expect(store.filter == PullRequestFilter(onlyConflicts: true))

        store.clearFilter()
        #expect(store.filter.isActive == false)
        #expect(harness.store.decode(PullRequestFilter.self, forKey: "gitlab.filter") == PullRequestFilter())
    }

    @Test func approveCallsGitLabLogsAndReloads() async throws {
        script([PullRequestSummaryFixture.open])
        await store.refresh()

        store.perform(.approve, on: 21)
        #expect(store.isBusy(21))

        try await waitUntil { store.isBusy(21) == false }
        #expect(harness.spies.codeHost.calls.contains(.approve(iid: 21, repository: remote)))
        #expect(harness.spies.codeHost.calls.filter { if case .list = $0 { true } else { false } }.count == 2)
        #expect(harness.lastActivity?.title == "Approved !21")
        #expect(harness.lastActivity?.detail == "ABC-5: Login")
    }

    @Test func retryPipelineNeedsThePipelineIDAndMergePassesTheOptions() async throws {
        let failed = PullRequestSummaryFixture.request(iid: 5, source: "x", state: .opened, pipeline: PipelineInfo(status: .failed, webURL: nil, updatedAt: nil, id: 90))
        script([failed, PullRequestSummaryFixture.open])
        await store.refresh()

        store.perform(.retryPipeline, on: 21)
        store.perform(.retryPipeline, on: 5)
        store.merge(21, kind: .merge, squash: false, removeSourceBranch: true)
        try await waitUntil { store.busyIDs.isEmpty }

        #expect(harness.spies.codeHost.calls.contains(.retryPipeline(id: 90, repository: remote)))
        #expect(harness.spies.codeHost.calls.contains(.merge(iid: 21, squash: false, removeSourceBranch: true, repository: remote)))
        #expect(harness.spies.codeHost.calls.filter { if case .retryPipeline = $0 { true } else { false } }.count == 1)
    }

    @Test func aFailedActionIsLoggedAsAFailure() async throws {
        script([PullRequestSummaryFixture.open])
        await store.refresh()
        harness.spies.codeHost.actionError = PullRequestError.command("403 Forbidden")

        store.perform(.markDraft, on: 21)
        try await waitUntil { store.isBusy(21) == false }

        #expect(harness.lastActivity?.title == "Cannot mark !21 as draft")
        #expect(harness.lastActivity?.outcome == .failure)
        #expect(harness.lastActivity?.detail == "403 Forbidden")
    }

    @Test func mergeFromTheMenuUsesTheDefaultsOfTheRequest() async throws {
        script([PullRequestSummaryFixture.request(iid: 21, source: "x", state: .opened, detail: .mergeable, squashOnMerge: false, removesSourceBranch: false)])
        await store.refresh()

        store.perform(.merge, on: 21)
        try await waitUntil { store.isBusy(21) == false }

        #expect(harness.spies.codeHost.calls.contains(.merge(iid: 21, squash: false, removeSourceBranch: false, repository: remote)))
    }

    @Test func aVisitShowsTheLastVisitAndRemembersThisOnePerScope() {
        let first = Date(timeIntervalSince1970: 1_000)
        let second = Date(timeIntervalSince1970: 2_000)

        store.beginVisit(now: first)
        #expect(store.seenAt == nil)

        store.beginVisit(now: second)
        #expect(store.seenAt == first)

        store.scope = .all
        store.beginVisit(now: second)
        #expect(store.seenAt == nil)
        #expect(harness.store.decode(Date.self, forKey: "gitlab.seenAt.all") == second)
        #expect(harness.store.decode(Date.self, forKey: "gitlab.seenAt.mine") == second)
    }

    @Test func autoMergeSendsTheHeadSHA() async throws {
        script([PullRequestSummaryFixture.request(iid: 21, source: "x", state: .opened, detail: .ciStillRunning, headSHA: "abc123")])
        await store.refresh()

        store.merge(21, kind: .mergeWhenPipelinePasses, squash: true, removeSourceBranch: false)
        try await waitUntil { store.isBusy(21) == false && harness.spies.codeHost.calls.contains { if case .setAutoMerge = $0 { true } else { false } } }

        #expect(harness.spies.codeHost.calls.contains(.setAutoMerge(iid: 21, sha: "abc123", squash: true, removeSourceBranch: false, repository: remote)))
        #expect(harness.lastActivity?.title == "!21 merges when the pipeline passes")
    }

    @Test func autoMergeWithoutTheHeadSHAIsAFailure() async {
        script([PullRequestSummaryFixture.request(iid: 21, source: "x", state: .opened, headSHA: nil)])
        await store.refresh()

        store.merge(21, kind: .mergeWhenPipelinePasses, squash: true, removeSourceBranch: true)

        #expect(harness.lastActivity?.title == "Cannot set auto-merge for !21")
        #expect(harness.lastActivity?.outcome == .failure)
        #expect(harness.spies.codeHost.calls.contains { if case .setAutoMerge = $0 { true } else { false } } == false)
    }

    @Test func cancelAutoMergeAndCancelPipeline() async throws {
        script([PullRequestSummaryFixture.request(iid: 21, source: "x", state: .opened, pipeline: PipelineInfo(status: .running, webURL: nil, updatedAt: nil, id: 90), isAutoMergeEnabled: true)])
        await store.refresh()

        store.perform(.cancelAutoMerge, on: 21)
        try await waitUntil { store.isBusy(21) == false }
        store.perform(.cancelPipeline, on: 21)
        try await waitUntil { store.isBusy(21) == false && harness.spies.codeHost.calls.contains(.cancelPipeline(id: 90, repository: remote)) }

        #expect(harness.spies.codeHost.calls.contains(.cancelAutoMerge(iid: 21, repository: remote)))
    }

    @Test func revealExpandsALoadedRequest() async {
        script([PullRequestSummaryFixture.open])
        await store.refresh()
        let lists = listCalls

        await store.reveal(21)

        #expect(store.expandedID == 21)
        #expect(store.revealedID == 21)
        #expect(store.scope == .mine)
        #expect(listCalls == lists)
    }

    @Test func revealOfAMissingRequestLooksInAllOpenThenEveryState() async {
        script([PullRequestSummaryFixture.open])
        await store.refresh()
        store.filter.onlyConflicts = true

        await store.reveal(99)

        #expect(store.scope == .all)
        #expect(store.stateFilter == .all)
        #expect(store.filter == PullRequestFilter())
        #expect(store.expandedID == 99)
        #expect(harness.spies.codeHost.calls.contains(.list(PullRequestQuery(scope: .all, state: .opened), after: nil, repository: remote)))
        #expect(harness.spies.codeHost.calls.contains(.list(PullRequestQuery(scope: .all, state: .all), after: nil, repository: remote)))
    }

    private var listCalls: Int {
        harness.spies.codeHost.calls.filter { if case .list = $0 { true } else { false } }.count
    }

    @Test func loadMoreAppendsTheNextPage() async {
        harness.spies.git.webURLResult = remote.webURL
        harness.spies.codeHost.listResult = .success(PullRequestList(username: "me", requests: [PullRequestSummaryFixture.open], totalCount: 3, endCursor: "c1", hasNextPage: true))
        harness.spies.codeHost.nextPageResult = .success(PullRequestList(
            username: "me",
            requests: [PullRequestSummaryFixture.open, PullRequestSummaryFixture.request(iid: 5, source: "x", state: .opened)],
            totalCount: 3,
            endCursor: "c2",
            hasNextPage: false
        ))
        await store.refresh()
        #expect(store.hasMore)

        await store.loadMore()

        #expect(store.requests.map(\.iid) == [21, 5])
        #expect(store.hasMore == false)
        #expect(harness.spies.codeHost.calls.last == .list(PullRequestQuery(scope: .mine, state: .opened), after: "c1", repository: remote))
    }

    @Test func aFailedPageIsLoggedAndKeepsTheCursor() async {
        harness.spies.git.webURLResult = remote.webURL
        harness.spies.codeHost.listResult = .success(PullRequestList(username: "me", requests: [PullRequestSummaryFixture.open], totalCount: 3, endCursor: "c1", hasNextPage: true))
        harness.spies.codeHost.nextPageResult = .failure(PullRequestError.command("502"))
        await store.refresh()

        await store.loadMore()

        #expect(store.nextCursor == "c1")
        #expect(store.isLoadingMore == false)
        #expect(harness.lastActivity?.title == "Cannot read more merge requests")
    }

    @Test func aRefreshStartsFromTheFirstPage() async {
        harness.spies.git.webURLResult = remote.webURL
        harness.spies.codeHost.listResult = .success(PullRequestList(username: "me", requests: [PullRequestSummaryFixture.open], totalCount: 1, endCursor: "c1", hasNextPage: false))

        await store.refresh()
        await store.loadMore()

        #expect(store.nextCursor == nil)
        #expect(harness.spies.codeHost.calls.filter { if case .list(_, let after, _) = $0 { after != nil } else { false } }.isEmpty)
    }

    @Test func aScopeLoadedBeforeShowsItsListAtOnce() async {
        let mine = PullRequestSummaryFixture.request(iid: 1, source: "mine", state: .opened, author: "me")
        script([mine])
        await store.refresh()
        store.scope = .all
        #expect(store.requests.isEmpty)
        #expect(store.hasLoaded == false)
        script([PullRequestSummaryFixture.open])
        await store.refresh()

        store.scope = .mine

        #expect(store.requests == [mine])
        #expect(store.hasLoaded)
        #expect(store.username == "me")
    }

    @Test func aFreshCachedScopeIsNotReadAgain() async {
        script([PullRequestSummaryFixture.open])
        await store.refresh()
        store.scope = .all
        await store.refresh()
        let lists = listCalls

        store.scope = .mine
        await store.refreshIfStale()

        #expect(listCalls == lists)
    }

    @Test func theCacheKeepsLoadedPagesAndClearsOnProjectChange() async {
        harness.spies.git.webURLResult = remote.webURL
        harness.spies.codeHost.listResult = .success(PullRequestList(username: "me", requests: [PullRequestSummaryFixture.open], totalCount: 2, endCursor: "c1", hasNextPage: true))
        harness.spies.codeHost.nextPageResult = .success(PullRequestList(username: "me", requests: [PullRequestSummaryFixture.request(iid: 5, source: "x", state: .opened)], totalCount: 2))
        await store.refresh()
        await store.loadMore()
        store.scope = .all

        store.scope = .mine
        #expect(store.requests.map(\.iid) == [21, 5])
        #expect(store.hasMore == false)

        harness.events.post(.projectChanged)
        store.scope = .all
        store.scope = .mine
        #expect(store.requests.isEmpty)
        #expect(store.hasLoaded == false)
    }

    @Test func toggleExpandedKeepsOneRowOpen() {
        store.toggleExpanded(1)
        #expect(store.expandedID == 1)

        store.toggleExpanded(2)
        #expect(store.expandedID == 2)

        store.toggleExpanded(2)
        #expect(store.expandedID == nil)
    }

    @Test func projectChangedClearsEverything() async {
        script([PullRequestSummaryFixture.open])
        await store.refresh()
        store.toggleExpanded(21)

        harness.events.post(.projectChanged)

        #expect(store.requests.isEmpty)
        #expect(store.username == nil)
        #expect(store.hasLoaded == false)
        #expect(store.expandedID == nil)
    }
}
