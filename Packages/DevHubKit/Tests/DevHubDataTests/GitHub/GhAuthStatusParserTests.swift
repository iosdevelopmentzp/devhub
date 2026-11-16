import DevHubDomain
import Foundation
import Testing
@testable import DevHubData

@Suite struct GhAuthStatusParserTests {
    @Test func readsTheLoginAndScopesOfTheActiveAccount() throws {
        let data = Data(#"{"hosts":{"github.com":[{"state":"success","active":false,"login":"sam","scopes":"repo"},{"state":"success","active":true,"login":"alex","scopes":"gist, read:org, repo"}]}}"#.utf8)

        #expect(try GhAuthStatusParser.access(from: data, host: "github.com") == CodeHostAccess(login: "alex", scopes: ["gist", "read:org", "repo"]))
    }

    @Test func noScopesMeansUnknown() throws {
        let data = Data(#"{"hosts":{"github.com":[{"state":"success","active":true,"login":"alex","scopes":""}]}}"#.utf8)

        #expect(try GhAuthStatusParser.access(from: data, host: "github.com").scopes == nil)
    }

    @Test func noAccountOrAFailedOneIsNotLoggedIn() {
        #expect(throws: PullRequestError.notLoggedIn(tool: "gh", host: "github.com")) {
            try GhAuthStatusParser.access(from: Data(#"{"hosts":{}}"#.utf8), host: "github.com")
        }
        #expect(throws: PullRequestError.notLoggedIn(tool: "gh", host: "github.com")) {
            try GhAuthStatusParser.access(from: Data(#"{"hosts":{"github.com":[{"state":"error","active":true,"login":"alex"}]}}"#.utf8), host: "github.com")
        }
    }

    @Test func aBrokenAnswerThrows() {
        #expect(throws: PullRequestError.self) {
            try GhAuthStatusParser.access(from: Data("nope".utf8), host: "github.com")
        }
    }
}
