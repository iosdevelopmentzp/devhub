import Foundation
import Testing
@testable import DevHubData

@Suite struct JiraDateParserTests {
    @Test func anOffsetWithoutAColonIsRead() throws {
        let date = try #require(JiraDateParser.date(from: "2026-11-06T13:11:45.043+0000"))

        #expect(date == Date(timeIntervalSince1970: 1_793_970_705.043).rounded())
    }

    @Test func aNegativeOffsetAndAPlainZuluTimeAreRead() {
        #expect(JiraDateParser.date(from: "2026-11-06T13:11:45.043-0500") == Date(timeIntervalSince1970: 1_793_970_705.043 + 5 * 3_600).rounded())
        #expect(JiraDateParser.date(from: "2026-11-01T10:00:00Z") == Date(timeIntervalSince1970: 1_793_527_200))
        #expect(JiraDateParser.date(from: "2026-11-01T10:00:00.000Z") == Date(timeIntervalSince1970: 1_793_527_200))
    }

    @Test func junkIsNil() {
        #expect(JiraDateParser.date(from: "yesterday") == nil)
        #expect(JiraDateParser.date(from: "") == nil)
    }

    @Test func aDayIsTheStartOfThatDayInTheCalendar() throws {
        let calendar = try utcCalendar()

        #expect(JiraDateParser.day(from: "2026-11-20", calendar: calendar) == Date(timeIntervalSince1970: 1_795_132_800))
        #expect(JiraDateParser.day(from: "2026-11-01", calendar: calendar) == Date(timeIntervalSince1970: 1_793_491_200))
    }

    @Test func aDayFollowsTheTimeZoneOfTheCalendar() throws {
        var calendar = try utcCalendar()
        calendar.timeZone = try #require(TimeZone(secondsFromGMT: 2 * 3_600))

        #expect(JiraDateParser.day(from: "2026-11-20", calendar: calendar) == Date(timeIntervalSince1970: 1_795_132_800 - 2 * 3_600))
    }

    @Test func anythingButAPlainDayIsNil() throws {
        let calendar = try utcCalendar()

        #expect(JiraDateParser.day(from: "2026-11-20T10:00:00Z", calendar: calendar) == nil)
        #expect(JiraDateParser.day(from: "2026-11-20T10:00:00.000+0000", calendar: calendar) == nil)
        #expect(JiraDateParser.day(from: "20-11-2026", calendar: calendar) == nil)
        #expect(JiraDateParser.day(from: "2026-1-5", calendar: calendar) == nil)
        #expect(JiraDateParser.day(from: "2026-13-40", calendar: calendar) == nil)
        #expect(JiraDateParser.day(from: "2026-02-30", calendar: calendar) == nil)
        #expect(JiraDateParser.day(from: " 2026-11-20", calendar: calendar) == nil)
        #expect(JiraDateParser.day(from: "2026-11-20\n", calendar: calendar) == nil)
        #expect(JiraDateParser.day(from: "tomorrow", calendar: calendar) == nil)
        #expect(JiraDateParser.day(from: "", calendar: calendar) == nil)
    }

    private func utcCalendar() throws -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(secondsFromGMT: 0))
        return calendar
    }
}

private extension Date {
    func rounded() -> Date {
        Date(timeIntervalSince1970: (timeIntervalSince1970 * 1_000).rounded() / 1_000)
    }
}
