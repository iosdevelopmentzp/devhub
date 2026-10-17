import Testing
@testable import DevHubDomain

@Suite struct ReviewQueuePolicyTests {
    @Test func anOpenRequestByAnotherPersonNeedsMyReview() {
        #expect(ReviewQueuePolicy.needsMyReview(MergeRequestSummaryFixture.request(iid: 1, source: "a", state: .opened), username: "me"))
    }

    @Test(arguments: [
        MergeRequestSummaryFixture.request(iid: 1, source: "a", state: .opened, author: "me"),
        MergeRequestSummaryFixture.request(iid: 2, source: "b", state: .opened, isDraft: true),
        MergeRequestSummaryFixture.request(iid: 3, source: "c", state: .merged),
        MergeRequestSummaryFixture.request(iid: 4, source: "d", state: .opened, approvedBy: ["kim", "me"]),
    ])
    func otherRequestsDoNot(request: MergeRequestSummary) {
        #expect(ReviewQueuePolicy.needsMyReview(request, username: "me") == false)
    }

    @Test func countCountsOnlyTheQueue() {
        let requests = [
            MergeRequestSummaryFixture.request(iid: 1, source: "a", state: .opened),
            MergeRequestSummaryFixture.request(iid: 2, source: "b", state: .opened, approvedBy: ["kim"]),
            MergeRequestSummaryFixture.request(iid: 3, source: "c", state: .opened, author: "me"),
        ]

        #expect(ReviewQueuePolicy.count(in: requests, username: "me") == 2)
    }
}
