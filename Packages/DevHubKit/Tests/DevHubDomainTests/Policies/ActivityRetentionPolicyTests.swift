import Foundation
import Testing
@testable import DevHubDomain

@Suite struct ActivityRetentionPolicyTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    @Test func dropsEventsOlderThanThirtyDays() {
        let fresh = event(daysAgo: 29)
        let edge = event(daysAgo: 30)
        let old = event(daysAgo: 31)

        #expect(ActivityRetentionPolicy.retained([fresh, edge, old], now: now) == [fresh, edge])
    }

    @Test func keepsAtMostTheLimitInTheGivenOrder() {
        let events = (0..<510).map { _ in event(daysAgo: 0) }

        let retained = ActivityRetentionPolicy.retained(events, now: now)

        #expect(retained.count == ActivityRetentionPolicy.limit)
        #expect(retained == Array(events.prefix(500)))
    }

    private func event(daysAgo: Int) -> ActivityEvent {
        ActivityEvent(id: UUID(), title: "e", detail: "", date: now.addingTimeInterval(-Double(daysAgo) * 86_400), outcome: .info)
    }
}
