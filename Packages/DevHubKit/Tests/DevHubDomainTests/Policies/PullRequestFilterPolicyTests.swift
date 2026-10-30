import Testing
@testable import DevHubDomain

@Suite struct PullRequestFilterPolicyTests {
    private let requests = [
        PullRequestSummaryFixture.request(iid: 1, source: "a", state: .opened, author: "alex", detail: .mergeable, labels: ["feature"], assignees: ["sam"], reviewers: ["kim"]),
        PullRequestSummaryFixture.request(iid: 2, source: "b", state: .opened, hasConflicts: true, detail: .needRebase, labels: ["bug", "tech"], target: "main"),
        PullRequestSummaryFixture.request(iid: 3, source: "c", state: .opened, labels: ["tech"], reviewers: ["kim", "alex"]),
    ]

    @Test func anEmptyFilterKeepsEverything() {
        #expect(PullRequestFilterPolicy.apply(PullRequestFilter(), to: requests).map(\.iid) == [1, 2, 3])
        #expect(PullRequestFilter().isActive == false)
    }

    @Test(arguments: [
        (PullRequestFilter(targetBranch: "main"), [2]),
        (PullRequestFilter(labels: ["tech"]), [2, 3]),
        (PullRequestFilter(labels: ["tech", "bug"]), [2]),
        (PullRequestFilter(author: "alex"), [1]),
        (PullRequestFilter(assignee: "sam"), [1]),
        (PullRequestFilter(reviewer: "kim"), [1, 3]),
        (PullRequestFilter(onlyConflicts: true), [2]),
        (PullRequestFilter(onlyReady: true), [1]),
        (PullRequestFilter(targetBranch: "dev", labels: ["tech"]), [3]),
        (PullRequestFilter(labels: ["missing"]), []),
    ])
    func eachFilterNarrowsTheList(filter: PullRequestFilter, iids: [Int]) {
        #expect(PullRequestFilterPolicy.apply(filter, to: requests).map(\.iid) == iids)
        #expect(filter.isActive)
    }

    @Test func optionsAreSortedAndKeepTheChosenValues() {
        let filter = PullRequestFilter(targetBranch: "release", labels: ["old"], author: "robin", assignee: "pat", reviewer: "lee")
        let options = PullRequestFilterPolicy.options(in: requests, keeping: filter)

        #expect(options.targetBranches == ["dev", "main", "release"])
        #expect(options.labels == ["bug", "feature", "old", "tech"])
        #expect(options.authors == ["alex", "robin", "sam"])
        #expect(options.assignees == ["pat", "sam"])
        #expect(options.reviewers == ["alex", "kim", "lee"])
    }

    @Test func optionsSortWithoutCase() {
        let mixed = [PullRequestSummaryFixture.request(iid: 1, source: "a", state: .opened, labels: ["Zebra", "apple", "Mango"])]

        #expect(PullRequestFilterPolicy.options(in: mixed, keeping: PullRequestFilter()).labels == ["apple", "Mango", "Zebra"])
    }
}
