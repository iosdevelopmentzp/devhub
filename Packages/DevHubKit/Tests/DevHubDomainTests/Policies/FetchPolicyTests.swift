import Foundation
import Testing
@testable import DevHubDomain

@Suite struct FetchPolicyTests {
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    @Test func zeroMinutesNeverFetches() {
        #expect(FetchPolicy.shouldFetch(lastFetch: nil, everyMinutes: 0, now: now) == false)
        #expect(FetchPolicy.shouldFetch(lastFetch: now.addingTimeInterval(-86_400), everyMinutes: 0, now: now) == false)
    }

    @Test func aRepositoryNeverFetchedFetches() {
        #expect(FetchPolicy.shouldFetch(lastFetch: nil, everyMinutes: 15, now: now))
    }

    @Test func fetchesOnlyWhenTheLastFetchIsOldEnough() {
        #expect(FetchPolicy.shouldFetch(lastFetch: now.addingTimeInterval(-14 * 60), everyMinutes: 15, now: now) == false)
        #expect(FetchPolicy.shouldFetch(lastFetch: now.addingTimeInterval(-15 * 60), everyMinutes: 15, now: now))
    }
}
