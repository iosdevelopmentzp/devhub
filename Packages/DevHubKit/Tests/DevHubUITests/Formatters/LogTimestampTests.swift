import Foundation
import Testing
@testable import DevHubUI

@Suite struct LogTimestampTests {
    @Test func nilDateGivesEmptyText() {
        #expect(LogTimestamp.text(nil) == "")
    }

    @Test func dateUsesHoursMinutesSecondsAndMillisecondsInCurrentZone() throws {
        var components = DateComponents()
        components.year = 2026
        components.month = 10
        components.day = 10
        components.hour = 14
        components.minute = 2
        components.second = 17
        components.nanosecond = 500_000_000
        let date = try #require(Calendar.current.date(from: components))
        let formatter = DateFormatter()
        formatter.timeZone = .current
        formatter.dateFormat = "HH:mm:ss.SSS"

        #expect(LogTimestamp.text(date) == formatter.string(from: date))
        #expect(LogTimestamp.text(date).hasSuffix(":02:17.500"))
    }
}
