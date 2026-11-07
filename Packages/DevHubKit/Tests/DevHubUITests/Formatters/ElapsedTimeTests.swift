import Testing
@testable import DevHubUI

@Suite struct ElapsedTimeTests {
    @Test func minutesAndSeconds() {
        #expect(ElapsedTime.text(0) == "0:00")
        #expect(ElapsedTime.text(7.9) == "0:07")
        #expect(ElapsedTime.text(80) == "1:20")
        #expect(ElapsedTime.text(725) == "12:05")
    }

    @Test func hoursWhenNeeded() {
        #expect(ElapsedTime.text(3723) == "1:02:03")
    }

    @Test func negativeIsZero() {
        #expect(ElapsedTime.text(-5) == "0:00")
    }
}
