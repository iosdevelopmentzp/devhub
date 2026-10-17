import Foundation
import Testing
@testable import DevHubDomain

@Suite struct NetworkRequestFilterTests {
    @Test(arguments: [
        (200, false, false),
        (399, false, false),
        (400, false, true),
        (503, false, true),
        (200, true, true),
    ])
    func failedMeansStatus400OrMoreOrAFailure(statusCode: Int, isFailure: Bool, expected: Bool) {
        let request = NetworkRequestFixture.request(statusCode: statusCode, duration: nil, isFailure: isFailure)

        #expect(NetworkRequestFilter.failed.matches(request) == expected)
        #expect(NetworkRequestFilter.all.matches(request))
    }

    @Test func aFailureWithoutStatusIsFailed() {
        #expect(NetworkRequestFilter.failed.matches(NetworkRequestFixture.request(statusCode: nil, duration: nil, isFailure: true)))
    }

    @Test(arguments: [
        (TimeInterval?.none, false),
        (0.5, false),
        (1.0, false),
        (1.01, true),
    ])
    func slowMeansLongerThanOneSecond(duration: TimeInterval?, expected: Bool) {
        let request = NetworkRequestFixture.request(statusCode: 200, duration: duration, isFailure: false)

        #expect(NetworkRequestFilter.slow.matches(request) == expected)
    }

    @Test func rawValuesStayStableForSavedFilters() {
        #expect(NetworkRequestFilter.allCases.map(\.rawValue) == ["all", "failed", "slow"])
    }
}
