import DevHubDomain
import Foundation
import Testing

@Suite struct MergeRequestAgePolicyTests {
    private let now = Date(timeIntervalSince1970: 1_000_000_000)

    @Test func anOpenRequestIsStaleAfterFourteenDaysWithoutUpdate() {
        let old = request(.opened, updatedDaysAgo: 14)
        let fresh = request(.opened, updatedDaysAgo: 13)

        #expect(MergeRequestAgePolicy.isStale(old, now: now))
        #expect(MergeRequestAgePolicy.isStale(fresh, now: now) == false)
    }

    @Test func finishedOrUndatedRequestsAreNeverStale() {
        #expect(MergeRequestAgePolicy.isStale(request(.merged, updatedDaysAgo: 40), now: now) == false)
        #expect(MergeRequestAgePolicy.isStale(MergeRequestSummaryFixture.open, now: now) == false)
    }

    @Test func aRequestIsNewWhenUpdatedAfterTheLastVisit() {
        let request = request(.opened, updatedDaysAgo: 1)

        #expect(MergeRequestAgePolicy.isNew(request, seenAt: now.addingTimeInterval(-3 * 86_400)))
        #expect(MergeRequestAgePolicy.isNew(request, seenAt: now) == false)
        #expect(MergeRequestAgePolicy.isNew(request, seenAt: nil) == false)
    }

    private func request(_ state: MergeRequestState, updatedDaysAgo days: Double) -> MergeRequestSummary {
        MergeRequestSummaryFixture.request(iid: 1, source: "x", state: state, updatedAt: now.addingTimeInterval(-days * 86_400))
    }
}
