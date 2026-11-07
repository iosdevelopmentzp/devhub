import Testing
@testable import DevHubDomain

@Suite struct ReviewQueuePolicyTests {
    private let me = ReviewerIdentity(username: "me")
    private let assigned = ReviewerIdentity(username: "me", teams: ["example/ios"], rule: .assigned)

    @Test func anOpenRequestByAnotherPersonNeedsMyReview() {
        #expect(ReviewQueuePolicy.needsMyReview(PullRequestSummaryFixture.request(iid: 1, source: "a", state: .opened), reviewer: me))
    }

    @Test(arguments: [
        PullRequestSummaryFixture.request(iid: 1, source: "a", state: .opened, author: "me"),
        PullRequestSummaryFixture.request(iid: 2, source: "b", state: .opened, isDraft: true),
        PullRequestSummaryFixture.request(iid: 3, source: "c", state: .merged),
        PullRequestSummaryFixture.request(iid: 4, source: "d", state: .opened, approvedBy: ["kim", "me"]),
    ])
    func otherRequestsDoNot(request: PullRequestSummary) {
        #expect(ReviewQueuePolicy.needsMyReview(request, reviewer: me) == false)
        #expect(ReviewQueuePolicy.needsMyReview(request, reviewer: assigned) == false)
    }

    @Test func countCountsOnlyTheQueue() {
        let requests = [
            PullRequestSummaryFixture.request(iid: 1, source: "a", state: .opened),
            PullRequestSummaryFixture.request(iid: 2, source: "b", state: .opened, approvedBy: ["kim"]),
            PullRequestSummaryFixture.request(iid: 3, source: "c", state: .opened, author: "me"),
        ]

        #expect(ReviewQueuePolicy.count(in: requests, reviewer: me) == 2)
    }

    @Test(arguments: [
        PullRequestSummaryFixture.request(iid: 1, source: "a", state: .opened, reviewers: ["me"]),
        PullRequestSummaryFixture.request(iid: 2, source: "b", state: .opened, assignees: ["me"]),
        PullRequestSummaryFixture.request(iid: 3, source: "c", state: .opened, requestedTeams: ["Example/iOS"]),
    ])
    func theAssignedRuleTakesRequestsThatNameMeOrMyTeam(request: PullRequestSummary) {
        #expect(ReviewQueuePolicy.needsMyReview(request, reviewer: assigned))
    }

    @Test func theAssignedRuleSkipsRequestsForOtherPeopleAndTeams() {
        let requests = [
            PullRequestSummaryFixture.request(iid: 1, source: "a", state: .opened),
            PullRequestSummaryFixture.request(iid: 2, source: "b", state: .opened, reviewers: ["kim"], requestedTeams: ["example/qa"]),
        ]

        #expect(ReviewQueuePolicy.count(in: requests, reviewer: assigned) == 0)
        #expect(ReviewQueuePolicy.count(in: requests, reviewer: me) == 2)
    }

    @Test(arguments: [
        (nil, ReviewQueueRule.open),
        ("open", .open),
        (" Assigned ", .assigned),
        ("mine", .open),
    ] as [(String?, ReviewQueueRule)])
    func ruleReadsTheConfigValue(value: String?, rule: ReviewQueueRule) {
        #expect(ReviewQueuePolicy.rule(value) == rule)
    }
}
