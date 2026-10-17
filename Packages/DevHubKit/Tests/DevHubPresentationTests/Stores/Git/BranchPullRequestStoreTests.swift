import Foundation
import Testing
import DevHubDomain
import DevHubTestSupport
@testable import DevHubPresentation

@Suite struct BranchPullRequestStoreTests {
    private let harness = StoreHarness()
    private let status = PullRequestStatus(pullRequest: nil, pipeline: nil)

    private var store: BranchPullRequestStore {
        harness.branchPullRequest
    }

    private func loadBranch(_ state: GitRepositoryState) async {
        harness.spies.git.stateResult = .success(state)
        await harness.git.refresh()
    }

    @Test func refreshWithoutABranchDoesNothing() async {
        await store.refresh()

        #expect(harness.spies.codeHost.calls.isEmpty)
        #expect(store.loadedBranch == nil)
    }

    @Test func refreshLoadsTheStatusOfTheCurrentBranch() async {
        await loadBranch(GitStateSample.state)
        harness.spies.codeHost.statusResult = .success(status)

        await store.refresh()

        #expect(store.status == status)
        #expect(store.error == nil)
        #expect(store.isLoading == false)
        #expect(store.loadedBranch == "APP-12-login")
        #expect(harness.spies.codeHost.calls == [.status(branch: "APP-12-login", repository: .gitLabSample)])
    }

    @Test func aPullRequestErrorIsSurfaced() async {
        await loadBranch(GitStateSample.state)
        harness.spies.codeHost.statusResult = .failure(PullRequestError.notLoggedIn(tool: "glab", host: "gitlab.example.com"))

        await store.refresh()

        #expect(store.error == .notLoggedIn(tool: "glab", host: "gitlab.example.com"))
        #expect(store.loadedBranch == "APP-12-login")
    }

    @Test func anyOtherErrorBecomesACommandError() async {
        let failure = TestError.scripted("boom")
        await loadBranch(GitStateSample.state)
        harness.spies.codeHost.statusResult = .failure(failure)

        await store.refresh()

        #expect(store.error == .command(failure.localizedDescription))
    }

    @Test func refreshIfStaleSkipsAFreshResult() async {
        await loadBranch(GitStateSample.state)
        await store.refresh()

        await store.refreshIfStale()

        #expect(harness.spies.codeHost.calls.count == 1)
    }

    @Test func refreshIfStaleLoadsAnotherBranch() async {
        await loadBranch(GitStateSample.state)
        await store.refresh()
        await loadBranch(GitStateSample.otherBranch)

        await store.refreshIfStale()

        #expect(harness.spies.codeHost.calls.last == .status(branch: "APP-99-other", repository: .gitLabSample))
        #expect(store.loadedBranch == "APP-99-other")
    }

    @Test func projectChangedResetsEverything() async {
        await loadBranch(GitStateSample.state)
        harness.spies.codeHost.statusResult = .failure(PullRequestError.noCodeHost)
        await store.refresh()

        harness.events.post(.projectChanged)

        #expect(store.status == nil)
        #expect(store.error == nil)
        #expect(store.loadedBranch == nil)

        await loadBranch(GitStateSample.state)
        await store.refreshIfStale()

        #expect(harness.spies.codeHost.calls.count == 2)
    }
}
