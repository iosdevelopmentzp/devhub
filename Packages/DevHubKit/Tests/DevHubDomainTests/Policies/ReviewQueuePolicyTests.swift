import Testing
@testable import DevHubDomain

@Suite struct ReviewQueuePolicyTests {
    @Test func anOpenRequestByAnotherPersonNeedsMyReview() {
        #expect(ReviewQueuePolicy.needsMyReview(PullRequestSummaryFixture.request(iid: 1, source: "a", state: .opened), username: "me"))
    }

    @Test(arguments: [
        PullRequestSummaryFixture.request(iid: 1, source: "a", state: .opened, author: "me"),
        PullRequestSummaryFixture.request(iid: 2, source: "b", state: .opened, isDraft: true),
        PullRequestSummaryFixture.request(iid: 3, source: "c", state: .merged),
        PullRequestSummaryFixture.request(iid: 4, source: "d", state: .opened, approvedBy: ["kim", "me"]),
    ])
    func otherRequestsDoNot(request: PullRequestSummary) {
        #expect(ReviewQueuePolicy.needsMyReview(request, username: "me") == false)
    }

    @Test func countCountsOnlyTheQueue() {
        let requests = [
            PullRequestSummaryFixture.request(iid: 1, source: "a", state: .opened),
            PullRequestSummaryFixture.request(iid: 2, source: "b", state: .opened, approvedBy: ["kim"]),
            PullRequestSummaryFixture.request(iid: 3, source: "c", state: .opened, author: "me"),
        ]

        #expect(ReviewQueuePolicy.count(in: requests, username: "me") == 2)
    }
}
