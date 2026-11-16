import DevHubDomain
import Foundation
import Testing
@testable import DevHubData

@Suite struct GlabAccessParserTests {
    @Test func readsTheUserNameAndTheTokenScopes() throws {
        #expect(try GlabAccessParser.login(from: Data(#"{"id":1,"username":"alex"}"#.utf8)) == "alex")
        #expect(try GlabAccessParser.scopes(from: Data(#"{"id":2,"scopes":["read_api","api"],"active":true}"#.utf8)) == ["read_api", "api"])
    }

    @Test func aBrokenAnswerThrows() {
        #expect(throws: PullRequestError.self) {
            try GlabAccessParser.login(from: Data("[]".utf8))
        }
    }
}
