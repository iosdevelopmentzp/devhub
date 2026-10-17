import DevHubDomain
import DevHubTestSupport
import Foundation
import Testing
@testable import DevHubData

@Suite struct CodeHostMergeRequestRepositoryTests {
    @Test func eachKindGoesToItsRepository() async throws {
        let gitHub = SpyMergeRequestRepository()
        let gitLab = SpyMergeRequestRepository()
        let repository = CodeHostMergeRequestRepository(gitHub: gitHub, gitLab: gitLab)

        try await repository.approve(iid: 1, repository: .gitHubSample)
        try await repository.approve(iid: 2, repository: .gitLabSample)

        #expect(gitHub.calls == [.approve(iid: 1, repository: .gitHubSample)])
        #expect(gitLab.calls == [.approve(iid: 2, repository: .gitLabSample)])
    }
}
