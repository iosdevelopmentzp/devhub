import Testing
@testable import DevHubData

@Suite struct FFmpegVersionParserTests {
    @Test func theFirstLineGivesTheVersion() {
        #expect(FFmpegVersionParser.version(from: FFmpegFixture.version) == "9.0.2")
    }

    @Test func otherOutputGivesNothing() {
        #expect(FFmpegVersionParser.version(from: "command not found") == nil)
    }
}
