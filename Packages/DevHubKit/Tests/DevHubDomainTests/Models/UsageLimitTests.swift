import Testing
@testable import DevHubDomain

@Suite struct UsageLimitTests {
    @Test(arguments: [(0.0, "0%"), (0.004, "0%"), (0.123, "12%"), (0.5, "50%"), (0.996, "100%"), (1.0, "100%")])
    func percentTextRoundsToAWholePercent(fraction: Double, text: String) {
        let limit = UsageLimit(id: "five_hour", title: "5 hours", usedFraction: fraction, resetsAt: nil)

        #expect(limit.percentText == text)
    }
}
