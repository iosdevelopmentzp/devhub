import Testing
@testable import DevHubDomain

@Suite struct MergeRequestFilterPolicyTests {
    private let requests = [
        MergeRequestSummaryFixture.request(iid: 1, source: "a", state: .opened, detail: .mergeable, labels: ["feature"]),
        MergeRequestSummaryFixture.request(iid: 2, source: "b", state: .opened, hasConflicts: true, detail: .needRebase, labels: ["bug", "tech"], target: "main"),
        MergeRequestSummaryFixture.request(iid: 3, source: "c", state: .opened, labels: ["tech"]),
    ]

    @Test func anEmptyFilterKeepsEverything() {
        #expect(MergeRequestFilterPolicy.apply(MergeRequestFilter(), to: requests).map(\.iid) == [1, 2, 3])
        #expect(MergeRequestFilter().isActive == false)
    }

    @Test(arguments: [
        (MergeRequestFilter(targetBranch: "main"), [2]),
        (MergeRequestFilter(label: "tech"), [2, 3]),
        (MergeRequestFilter(onlyConflicts: true), [2]),
        (MergeRequestFilter(onlyReady: true), [1]),
        (MergeRequestFilter(targetBranch: "dev", label: "tech"), [3]),
    ])
    func eachFilterNarrowsTheList(filter: MergeRequestFilter, iids: [Int]) {
        #expect(MergeRequestFilterPolicy.apply(filter, to: requests).map(\.iid) == iids)
        #expect(filter.isActive)
    }

    @Test func optionsAreSortedAndKeepTheChosenValues() {
        let options = MergeRequestFilterPolicy.options(in: requests, keeping: MergeRequestFilter(targetBranch: "release", label: "old"))

        #expect(options.targetBranches == ["dev", "main", "release"])
        #expect(options.labels == ["bug", "feature", "old", "tech"])
    }
}
