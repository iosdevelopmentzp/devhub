import DevHubDomain
import Foundation
import Testing

@Suite struct PullRequestAgePolicyTests {
    private let now = Date(timeIntervalSince1970: 1_000_000_000)

    @Test func anOpenRequestIsStaleAfterFourteenDaysWithoutUpdate() {
        let old = request(.opened, updatedDaysAgo: 14)
        let fresh = request(.opened, updatedDaysAgo: 13)

        #expect(PullRequestAgePolicy.isStale(old, now: now, staleDays: 14))
        #expect(PullRequestAgePolicy.isStale(fresh, now: now, staleDays: 14) == false)
    }

    @Test func theProjectSetsTheDays() {
        #expect(PullRequestAgePolicy.isStale(request(.opened, updatedDaysAgo: 3), now: now, staleDays: 3))
        #expect(PullRequestAgePolicy.isStale(request(.opened, updatedDaysAgo: 2), now: now, staleDays: 3) == false)
    }

    @Test func finishedOrUndatedRequestsAreNeverStale() {
        #expect(PullRequestAgePolicy.isStale(request(.merged, updatedDaysAgo: 40), now: now, staleDays: 14) == false)
        #expect(PullRequestAgePolicy.isStale(PullRequestSummaryFixture.open, now: now, staleDays: 14) == false)
    }

    @Test func aRequestIsNewWhenUpdatedAfterTheLastVisit() {
        let request = request(.opened, updatedDaysAgo: 1)

        #expect(PullRequestAgePolicy.isNew(request, seenAt: now.addingTimeInterval(-3 * 86_400)))
        #expect(PullRequestAgePolicy.isNew(request, seenAt: now) == false)
        #expect(PullRequestAgePolicy.isNew(request, seenAt: nil) == false)
    }

    private func request(_ state: PullRequestState, updatedDaysAgo days: Double) -> PullRequestSummary {
        PullRequestSummaryFixture.request(iid: 1, source: "x", state: state, updatedAt: now.addingTimeInterval(-days * 86_400))
    }
}
