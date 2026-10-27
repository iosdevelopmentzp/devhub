import DevHubDomain
import DevHubTestSupport
import Foundation
import Testing
@testable import DevHubData

@Suite struct RoutingCodeHostRepositoryTests {
    @Test func eachKindGoesToItsRepository() async throws {
        let gitHub = SpyCodeHostRepository()
        let gitLab = SpyCodeHostRepository()
        let repository = RoutingCodeHostRepository(gitHub: gitHub, gitLab: gitLab)

        try await repository.approve(iid: 1, repository: .gitHubSample)
        try await repository.approve(iid: 2, repository: .gitLabSample)

        #expect(gitHub.calls == [.approve(iid: 1, repository: .gitHubSample)])
        #expect(gitLab.calls == [.approve(iid: 2, repository: .gitLabSample)])
    }

    @Test func commentsGoToTheRepositoryOfTheirKind() async throws {
        let gitHub = SpyCodeHostRepository()
        let gitLab = SpyCodeHostRepository()
        let repository = RoutingCodeHostRepository(gitHub: gitHub, gitLab: gitLab)

        try await repository.comment(iid: 1, body: "a", repository: .gitHubSample)
        try await repository.requestChanges(iid: 1, body: "b", repository: .gitHubSample)
        try await repository.comment(iid: 2, body: "c", repository: .gitLabSample)

        #expect(gitHub.calls == [.comment(iid: 1, body: "a", repository: .gitHubSample), .requestChanges(iid: 1, body: "b", repository: .gitHubSample)])
        #expect(gitLab.calls == [.comment(iid: 2, body: "c", repository: .gitLabSample)])
    }
}
