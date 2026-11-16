import DevHubDomain
import Foundation
import Testing

@Suite struct PullRequestSubscriptionPolicyTests {
    private func request(_ iid: Int, author: String = "sam", state: PullRequestState = .opened, subscribed: Bool?) -> PullRequestSummary {
        PullRequestSummary(iid: iid, title: "ABC-123: Login", state: state, isDraft: false, webURL: nil, author: author, sourceBranch: "b\(iid)", targetBranch: "main", hasConflicts: false, detailedStatus: nil, commentCount: 0, updatedAt: nil, pipeline: nil, approvedBy: [], labels: [], isSubscribed: subscribed)
    }

    @Test func aChangeMadeInDevHubWinsOverTheLoadedState() {
        #expect(PullRequestSubscriptionPolicy.isSubscribed(request(1, subscribed: true), changes: [:]) == true)
        #expect(PullRequestSubscriptionPolicy.isSubscribed(request(1, subscribed: true), changes: [1: false]) == false)
        #expect(PullRequestSubscriptionPolicy.isSubscribed(request(1, subscribed: nil), changes: [:]) == nil)
    }

    @Test func onlyAnOpenRequestOfSomeoneElseCanChange() {
        #expect(PullRequestSubscriptionPolicy.canChange(request(1, subscribed: true), username: "alex"))
        #expect(PullRequestSubscriptionPolicy.canChange(request(1, author: "alex", subscribed: true), username: "alex") == false)
        #expect(PullRequestSubscriptionPolicy.canChange(request(1, state: .merged, subscribed: true), username: "alex") == false)
        #expect(PullRequestSubscriptionPolicy.canChange(request(1, subscribed: true), username: nil) == false)
    }

    @Test func othersToUnsubscribeAreTheSubscribedOpenRequestsOfOtherPeople() {
        let requests = [
            request(4, subscribed: true),
            request(2, subscribed: true),
            request(3, author: "alex", subscribed: true),
            request(5, subscribed: false),
            request(6, subscribed: nil),
            request(7, subscribed: true),
        ]

        let found = PullRequestSubscriptionPolicy.othersToUnsubscribe(requests, username: "alex", changes: [7: false])

        #expect(found.map(\.iid) == [2, 4])
    }

    @Test func toSubscribeAgainAreTheUnsubscribedOnesDevHubRemembers() {
        let requests = [
            request(2, subscribed: false),
            request(3, subscribed: false),
            request(4, subscribed: true),
            request(5, subscribed: true),
        ]

        let found = PullRequestSubscriptionPolicy.toSubscribeAgain(requests, unsubscribed: [2, 4, 5, 9], username: "alex", changes: [5: false])

        #expect(found.map(\.iid) == [2, 5])
    }
}
