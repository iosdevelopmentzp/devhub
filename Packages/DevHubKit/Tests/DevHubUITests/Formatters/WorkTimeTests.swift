import Testing
@testable import DevHubUI

@Suite struct WorkTimeTests {
    @Test func hoursAndMinutes() {
        #expect(WorkTime.text(seconds: 5_400) == "1h 30m")
        #expect(WorkTime.text(seconds: 14_400) == "4h")
        #expect(WorkTime.text(seconds: 1_800) == "30m")
        #expect(WorkTime.text(seconds: 59) == "0m")
    }

    @Test func aNegativeValueIsZero() {
        #expect(WorkTime.text(seconds: -60) == "0m")
    }
}
