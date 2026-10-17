import DevHubDomain
import DevHubTestSupport
import Foundation
import Testing
@testable import DevHubData

@Suite struct RoutingCodeHostRepositoryTests {
    @Test func eachKindGoesToItsRepository() async throws {
        let gitHub = SpyCodeHostRepository()
        let pullRequests = SpyCodeHostRepository()
        let repository = RoutingCodeHostRepository(gitHub: gitHub, pullRequests: pullRequests)

        try await repository.approve(iid: 1, repository: .gitHubSample)
        try await repository.approve(iid: 2, repository: .gitLabSample)

        #expect(gitHub.calls == [.approve(iid: 1, repository: .gitHubSample)])
        #expect(pullRequests.calls == [.approve(iid: 2, repository: .gitLabSample)])
    }
}
