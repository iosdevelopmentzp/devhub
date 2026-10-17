import DevHubDomain
import Foundation
import Testing
@testable import DevHubData

@Suite struct ClaudeCredentialsParserTests {
    @Test func readsTokenExpiryInMillisecondsAndPlan() throws {
        let credentials = try ClaudeCredentialsParser.parse(ClaudeUsageFixture.credentials)

        #expect(credentials.accessToken == "sk-ant-oat-fake")
        #expect(credentials.expiresAt == Date(timeIntervalSince1970: 1_767_323_045))
        #expect(credentials.subscriptionType == "max")
    }

    @Test func optionalFieldsMayBeMissing() throws {
        let credentials = try ClaudeCredentialsParser.parse(ClaudeUsageFixture.credentialsWithoutExtras)

        #expect(credentials.expiresAt == nil)
        #expect(credentials.subscriptionType == nil)
    }

    @Test(arguments: [
        ClaudeUsageFixture.credentialsWithEmptyToken,
        ClaudeUsageFixture.credentialsWithoutOAuth,
        ClaudeUsageFixture.notAnObject,
    ])
    func missingTokenThrowsNotLoggedIn(data: Data) {
        let error = #expect(throws: ClaudeUsageError.self) {
            try ClaudeCredentialsParser.parse(data)
        }
        guard case .notLoggedIn? = error else {
            Issue.record("Expected .notLoggedIn, got \(String(describing: error))")
            return
        }
    }

    @Test func invalidJSONThrows() {
        #expect(throws: (any Error).self) {
            try ClaudeCredentialsParser.parse(Data("not json".utf8))
        }
    }
}
