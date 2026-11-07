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
}

private extension Date {
    func rounded() -> Date {
        Date(timeIntervalSince1970: (timeIntervalSince1970 * 1_000).rounded() / 1_000)
    }
}
