import Testing
@testable import DevHubDomain

@Suite struct AppLogLineTests {
    @Test func levelsGrowFromDebugToFault() {
        #expect(AppLogLine.Level.allCases == [.debug, .info, .notice, .error, .fault])
        #expect(AppLogLine.Level.allCases.sorted() == AppLogLine.Level.allCases)
    }

    @Test func errorIsAboveNotice() {
        #expect(AppLogLine.Level.notice < .error)
        #expect((AppLogLine.Level.fault < .debug) == false)
    }
}
