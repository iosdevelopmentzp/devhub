import DevHubDomain
import Foundation
import Testing
@testable import DevHubData

@Suite struct GhTeamListParserTests {
    @Test func myTeamsKeepsOnlyTheTeamsOfTheRepositoryOwner() throws {
        let data = Data(#"[[{"slug":"ios","organization":{"login":"Example"}},{"slug":"web","organization":{"login":"other"}}],[{"slug":"qa","organization":{"login":"example"}},{"slug":"","organization":{"login":"example"}}]]"#.utf8)

        #expect(try GhTeamListParser.myTeams(from: data, owner: "example") == ["Example/ios", "example/qa"])
    }

    @Test func repositoryTeamsNameTheOwner() throws {
        let data = Data(#"[[{"slug":"qa"},{"slug":"ios"}],[{"slug":"qa"}]]"#.utf8)

        #expect(try GhTeamListParser.repositoryTeams(from: data, owner: "example") == ["example/ios", "example/qa"])
    }

    @Test func aPlainListIsReadToo() throws {
        #expect(try GhTeamListParser.repositoryTeams(from: Data(#"[{"slug":"ios"}]"#.utf8), owner: "example") == ["example/ios"])
    }

    @Test func aBrokenAnswerThrows() {
        #expect(throws: PullRequestError.self) {
            try GhTeamListParser.myTeams(from: Data(#"{"message":"Not Found"}"#.utf8), owner: "example")
        }
    }
}
