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

    @Test func peopleGoToTheRepositoryOfTheirKind() async throws {
        let gitHub = SpyCodeHostRepository()
        let gitLab = SpyCodeHostRepository()
        let repository = RoutingCodeHostRepository(gitHub: gitHub, gitLab: gitLab)

        _ = try await repository.people(repository: .gitHubSample)
        _ = try await repository.teams(repository: .gitHubSample)
        _ = try await repository.myTeams(repository: .gitHubSample)
        try await repository.updatePeople(iid: 2, role: .assignee, add: ["sam"], remove: [], repository: .gitLabSample)

        #expect(gitHub.calls == [.people(repository: .gitHubSample), .teams(repository: .gitHubSample), .myTeams(repository: .gitHubSample)])
        #expect(gitLab.calls == [.updatePeople(iid: 2, role: .assignee, add: ["sam"], remove: [], repository: .gitLabSample)])
    }

    @Test func subscriptionsGoToTheRepositoryOfTheirKind() async throws {
        let gitHub = SpyCodeHostRepository()
        let gitLab = SpyCodeHostRepository()
        let repository = RoutingCodeHostRepository(gitHub: gitHub, gitLab: gitLab)
        let request = PullRequestSummary(iid: 7, title: "ABC-123: Login", state: .opened, isDraft: false, webURL: nil, author: "sam", sourceBranch: "a", targetBranch: "main", hasConflicts: false, detailedStatus: nil, commentCount: 0, updatedAt: nil, pipeline: nil, approvedBy: [], labels: [])

        try await repository.setSubscribed(false, requests: [request], repository: .gitHubSample)
        try await repository.setSubscribed(true, requests: [request], repository: .gitLabSample)

        #expect(gitHub.calls == [.setSubscribed(false, iids: [7], repository: .gitHubSample)])
        #expect(gitLab.calls == [.setSubscribed(true, iids: [7], repository: .gitLabSample)])
    }

    @Test func accessGoesToTheRepositoryOfItsKind() async throws {
        let gitHub = SpyCodeHostRepository()
        let gitLab = SpyCodeHostRepository()
        let repository = RoutingCodeHostRepository(gitHub: gitHub, gitLab: gitLab)

        _ = try await repository.access(repository: .gitHubSample)
        _ = try await repository.access(repository: .gitLabSample)

        #expect(gitHub.calls == [.access(repository: .gitHubSample)])
        #expect(gitLab.calls == [.access(repository: .gitLabSample)])
    }
}
