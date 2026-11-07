import Testing
@testable import DevHubPresentation

@Suite struct TabIDTests {
    @Test func rawValuesRoundTrip() {
        #expect(TabID(rawValue: "git") == .feature(.git))
        #expect(TabID(rawValue: "tab.qa") == .custom("qa"))
        #expect(TabID(rawValue: "utility.compressVideo") == .utility(.compressVideo))
        #expect(TabID.feature(.logs).rawValue == "logs")
        #expect(TabID.custom("qa").rawValue == "tab.qa")
        #expect(TabID.utility(.compressVideo).rawValue == "utility.compressVideo")
    }

    @Test func unknownOrEmptyValuesAreNil() {
        #expect(TabID(rawValue: "scripts") == nil)
        #expect(TabID(rawValue: "tab.") == nil)
        #expect(TabID(rawValue: "utility.") == nil)
        #expect(TabID(rawValue: "utility.removedTool") == nil)
        #expect(TabID(rawValue: "compressVideo") == nil)
    }
}
