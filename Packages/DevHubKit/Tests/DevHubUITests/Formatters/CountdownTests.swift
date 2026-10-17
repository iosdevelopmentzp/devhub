import Testing
@testable import DevHubUI

@Suite struct CountdownTests {
    @Test func positiveIntervalGivesText() throws {
        let text = try #require(Countdown.text(2 * 3_600 + 15 * 60))
        #expect(text.isEmpty == false)
    }

    @Test func negativeIntervalIsClampedToZero() {
        #expect(Countdown.text(-500) != nil)
        #expect(Countdown.text(-500) == Countdown.text(0))
    }
}
