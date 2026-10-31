import Foundation
import Testing
@testable import DevHubUI

@Suite struct ClockTimeTests {
    @Test func dateUsesHoursMinutesAndSecondsInCurrentZone() throws {
        var components = DateComponents()
        components.year = 2026
        components.month = 10
        components.day = 10
        components.hour = 14
        components.minute = 2
        components.second = 17
        let date = try #require(Calendar.current.date(from: components))
        let formatter = DateFormatter()
        formatter.timeZone = .current
        formatter.dateFormat = "HH:mm:ss"

        #expect(ClockTime.text(date) == formatter.string(from: date))
        #expect(ClockTime.text(date).hasSuffix(":02:17"))
    }
}
