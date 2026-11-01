import DevHubDomain
import Foundation
import Testing
@testable import DevHubData

@Suite struct GhUserListParserTests {
    @Test func readsTheLoginsSortedWithoutCase() throws {
        let data = Data(#"[{"login":"sam","id":2},{"login":"Alex","id":1},{"id":3},{"login":""}]"#.utf8)

        #expect(try GhUserListParser.logins(from: data) == ["Alex", "sam"])
    }

    @Test func anEmptyListIsEmpty() throws {
        #expect(try GhUserListParser.logins(from: Data("[]".utf8)).isEmpty)
    }

    @Test func aBrokenAnswerThrows() {
        #expect(throws: PullRequestError.self) {
            try GhUserListParser.logins(from: Data(#"{"message":"Not Found"}"#.utf8))
        }
    }
}
