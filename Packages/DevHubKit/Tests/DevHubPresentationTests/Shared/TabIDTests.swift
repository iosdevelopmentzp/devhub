import Testing
@testable import DevHubPresentation

@Suite struct TabIDTests {
    @Test func rawValuesRoundTrip() {
        #expect(TabID(rawValue: "git") == .feature(.git))
        #expect(TabID(rawValue: "tab.qa") == .custom("qa"))
        #expect(TabID.feature(.logs).rawValue == "logs")
        #expect(TabID.custom("qa").rawValue == "tab.qa")
    }

    @Test func unknownOrEmptyValuesAreNil() {
        #expect(TabID(rawValue: "scripts") == nil)
        #expect(TabID(rawValue: "tab.") == nil)
    }
}
