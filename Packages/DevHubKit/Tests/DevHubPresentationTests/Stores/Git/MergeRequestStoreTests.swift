import Foundation
import Testing
import DevHubDomain
import DevHubTestSupport
@testable import DevHubPresentation

@Suite struct MergeRequestStoreTests {
    private let harness = StoreHarness()
    private let status = MergeRequestStatus(mergeRequest: nil, pipeline: nil)

    private var store: MergeRequestStore {
        harness.mergeRequests
    }

    private func loadBranch(_ state: GitRepositoryState) async {
        harness.spies.git.stateResult = .success(state)
        await harness.git.refresh()
    }

    @Test func refreshWithoutABranchDoesNothing() async {
        await store.refresh()

        #expect(harness.spies.mergeRequests.calls.isEmpty)
        #expect(store.loadedBranch == nil)
    }

    @Test func refreshLoadsTheStatusOfTheCurrentBranch() async {
        await loadBranch(GitStateSample.state)
        harness.spies.mergeRequests.statusResult = .success(status)

        await store.refresh()

        #expect(store.status == status)
        #expect(store.error == nil)
        #expect(store.isLoading == false)
        #expect(store.loadedBranch == "APP-12-login")
        #expect(harness.spies.mergeRequests.calls == [.status(branch: "APP-12-login", repository: GitStateSample.webURL)])
    }

    @Test func aMergeRequestErrorIsSurfaced() async {
        await loadBranch(GitStateSample.state)
        harness.spies.mergeRequests.statusResult = .failure(MergeRequestError.notLoggedIn(host: "gitlab.example.com"))

        await store.refresh()

        #expect(store.error == .notLoggedIn(host: "gitlab.example.com"))
        #expect(store.loadedBranch == "APP-12-login")
    }

    @Test func anyOtherErrorBecomesACommandError() async {
        let failure = TestError.scripted("boom")
        await loadBranch(GitStateSample.state)
        harness.spies.mergeRequests.statusResult = .failure(failure)

        await store.refresh()

        #expect(store.error == .command(failure.localizedDescription))
    }

    @Test func refreshIfStaleSkipsAFreshResult() async {
        await loadBranch(GitStateSample.state)
        await store.refresh()

        await store.refreshIfStale()

        #expect(harness.spies.mergeRequests.calls.count == 1)
    }

    @Test func refreshIfStaleLoadsAnotherBranch() async {
        await loadBranch(GitStateSample.state)
        await store.refresh()
        await loadBranch(GitStateSample.otherBranch)

        await store.refreshIfStale()

        #expect(harness.spies.mergeRequests.calls.last == .status(branch: "APP-99-other", repository: GitStateSample.webURL))
        #expect(store.loadedBranch == "APP-99-other")
    }

    @Test func projectChangedResetsEverything() async {
        await loadBranch(GitStateSample.state)
        harness.spies.mergeRequests.statusResult = .failure(MergeRequestError.notGitLab)
        await store.refresh()

        harness.events.post(.projectChanged)

        #expect(store.status == nil)
        #expect(store.error == nil)
        #expect(store.loadedBranch == nil)

        await loadBranch(GitStateSample.state)
        await store.refreshIfStale()

        #expect(harness.spies.mergeRequests.calls.count == 2)
    }
}
