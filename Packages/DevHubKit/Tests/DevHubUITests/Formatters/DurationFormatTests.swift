import Testing
@testable import DevHubUI

@Suite struct DurationFormatTests {
    @Test func underOneSecondShowsMilliseconds() {
        #expect(DurationFormat.text(0.25) == "250 ms")
        #expect(DurationFormat.text(0) == "0 ms")
        #expect(DurationFormat.text(0.999) == "999 ms")
    }

    @Test func underOneMinuteShowsSecondsWithOneDecimal() {
        #expect(DurationFormat.text(1) == "1.0 s")
        #expect(DurationFormat.text(12.34) == "12.3 s")
        #expect(DurationFormat.text(59.94) == "59.9 s")
    }

    @Test func oneMinuteAndMoreShowsMinutesAndSeconds() {
        #expect(DurationFormat.text(60) == "1 m 0 s")
        #expect(DurationFormat.text(125.7) == "2 m 5 s")
        #expect(DurationFormat.text(3_601) == "60 m 1 s")
    }

    @Test func runsOnMainActor() {
        MainActor.assertIsolated()
    }
}
