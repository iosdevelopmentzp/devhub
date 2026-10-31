import DevHubDomain
import DevHubTestSupport
import Foundation
import Testing
@testable import DevHubData

@Suite struct GhInboxParserTests {
    @Test func unreadThreadsOfTheRepositoryBecomeItems() throws {
        let threads = try GhInboxParser.threads(from: GhFixture.notifications, repository: .gitHubSample)

        #expect(threads.map(\.item.id) == ["901", "902", "903"])
        #expect(threads.map(\.item.kind) == [.mention, .reviewRequested, .assigned])
        #expect(threads.map(\.item.target) == [.pullRequest(iid: 12), .pullRequest(iid: 9), .issue(iid: 31)])
        #expect(threads.map(\.item.title) == ["ABC-123: Login screen", "ABC-120: Profile badges", "Crash on cold start"])
        #expect(threads.map(\.item.webURL?.absoluteString) == ["https://github.com/example/app/pull/12", "https://github.com/example/app/pull/9", "https://github.com/example/app/issues/31"])
        #expect(threads.map(\.item.actor) == [nil, nil, nil])
        #expect(threads[0].item.updatedAt != nil)
    }

    @Test func onlyACommentLikeThreadWithItsOwnCommentHasALookup() throws {
        let threads = try GhInboxParser.threads(from: GhFixture.notifications, repository: .gitHubSample)

        #expect(threads.map(\.latestCommentURL) == ["https://api.github.com/repos/example/app/issues/comments/501", nil, nil])
    }

    @Test func theActorComesFromTheComment() throws {
        let actor = try GhInboxParser.actor(from: GhFixture.comment)

        #expect(actor.login == "sam")
        #expect(actor.webURL?.absoluteString == "https://github.com/example/app/pull/12#issuecomment-501")
    }
}
