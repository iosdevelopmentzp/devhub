import Testing
@testable import DevHubDomain

@Suite struct PullRequestFilterPolicyTests {
    private let requests = [
        PullRequestSummaryFixture.request(iid: 1, source: "a", state: .opened, detail: .mergeable, labels: ["feature"]),
        PullRequestSummaryFixture.request(iid: 2, source: "b", state: .opened, hasConflicts: true, detail: .needRebase, labels: ["bug", "tech"], target: "main"),
        PullRequestSummaryFixture.request(iid: 3, source: "c", state: .opened, labels: ["tech"]),
    ]

    @Test func anEmptyFilterKeepsEverything() {
        #expect(PullRequestFilterPolicy.apply(PullRequestFilter(), to: requests).map(\.iid) == [1, 2, 3])
        #expect(PullRequestFilter().isActive == false)
    }

    @Test(arguments: [
        (PullRequestFilter(targetBranch: "main"), [2]),
        (PullRequestFilter(label: "tech"), [2, 3]),
        (PullRequestFilter(onlyConflicts: true), [2]),
        (PullRequestFilter(onlyReady: true), [1]),
        (PullRequestFilter(targetBranch: "dev", label: "tech"), [3]),
    ])
    func eachFilterNarrowsTheList(filter: PullRequestFilter, iids: [Int]) {
        #expect(PullRequestFilterPolicy.apply(filter, to: requests).map(\.iid) == iids)
        #expect(filter.isActive)
    }

    @Test func optionsAreSortedAndKeepTheChosenValues() {
        let options = PullRequestFilterPolicy.options(in: requests, keeping: PullRequestFilter(targetBranch: "release", label: "old"))

        #expect(options.targetBranches == ["dev", "main", "release"])
        #expect(options.labels == ["bug", "feature", "old", "tech"])
    }
}
