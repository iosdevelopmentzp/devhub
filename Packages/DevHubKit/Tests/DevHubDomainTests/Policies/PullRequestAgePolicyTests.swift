import DevHubDomain
import Foundation
import Testing

@Suite struct PullRequestAgePolicyTests {
    private let now = Date(timeIntervalSince1970: 1_000_000_000)

    @Test func anOpenRequestIsStaleAfterFourteenDaysWithoutUpdate() {
        let old = request(.opened, updatedDaysAgo: 14)
        let fresh = request(.opened, updatedDaysAgo: 13)

        #expect(PullRequestAgePolicy.isStale(old, now: now))
        #expect(PullRequestAgePolicy.isStale(fresh, now: now) == false)
    }

    @Test func finishedOrUndatedRequestsAreNeverStale() {
        #expect(PullRequestAgePolicy.isStale(request(.merged, updatedDaysAgo: 40), now: now) == false)
        #expect(PullRequestAgePolicy.isStale(PullRequestSummaryFixture.open, now: now) == false)
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
