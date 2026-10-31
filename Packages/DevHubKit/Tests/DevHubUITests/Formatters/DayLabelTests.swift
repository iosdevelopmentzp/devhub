import Foundation
import Testing
@testable import DevHubUI

@Suite struct DayLabelTests {
    private let calendar = Calendar(identifier: .gregorian)
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    @Test func todayAndYesterdayAreNamed() {
        #expect(DayLabel.text(for: now, now: now, calendar: calendar) == "Today")
        #expect(DayLabel.text(for: now.addingTimeInterval(-3600), now: now, calendar: calendar) == "Today")
        #expect(DayLabel.text(for: calendar.date(byAdding: .day, value: -1, to: now) ?? now, now: now, calendar: calendar) == "Yesterday")
    }

    @Test func anOlderDayGetsADateText() {
        let text = DayLabel.text(for: now.addingTimeInterval(-5 * 86_400), now: now, calendar: calendar)

        #expect(text.isEmpty == false)
        #expect(text != "Today")
        #expect(text != "Yesterday")
    }
}
