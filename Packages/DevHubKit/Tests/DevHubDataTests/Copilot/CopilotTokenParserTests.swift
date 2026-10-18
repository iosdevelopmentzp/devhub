import Testing
@testable import DevHubData

@Suite struct CopilotTokenParserTests {
    @Test func plainTextIsTheToken() {
        #expect(CopilotTokenParser.parse("  gho_example\n") == "gho_example")
        #expect(CopilotTokenParser.parse(" \n") == nil)
    }

    @Test func jsonGivesTheFirstKnownField() {
        #expect(CopilotTokenParser.parse(#"{"user":"dev","oauth_token":"gho_one"}"#) == "gho_one")
        #expect(CopilotTokenParser.parse(#"{"token":"","accessToken":"gho_two"}"#) == "gho_two")
        #expect(CopilotTokenParser.parse(#"{"user":"dev"}"#) == nil)
        #expect(CopilotTokenParser.parse("{broken") == nil)
    }
}
