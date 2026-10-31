import DevHubDomain
import Foundation
import Testing
@testable import DevHubData

@Suite struct GlabInboxParserTests {
    @Test func pendingTodosOfTheProjectBecomeItems() throws {
        let items = try GlabInboxParser.items(from: GlabFixture.todos, projectPath: "team/app")

        #expect(items.map(\.id) == ["701", "702", "703"])
        #expect(items.map(\.kind) == [.mention, .reviewRequested, .assigned])
        #expect(items.map(\.actor) == ["sam", "kim", "lee"])
        #expect(items.map(\.target) == [.pullRequest(iid: 12), .pullRequest(iid: 9), .issue(iid: 31)])
        #expect(items.map(\.title) == ["ABC-123: Login screen", "ABC-120: Profile badges", "Crash on cold start"])
        #expect(items.map(\.excerpt) == ["@alex can you check the retry path?", nil, nil])
        #expect(items[0].webURL?.absoluteString == "https://gitlab.example.com/team/app/-/merge_requests/12")
        #expect(items[0].updatedAt != nil)
    }
}
