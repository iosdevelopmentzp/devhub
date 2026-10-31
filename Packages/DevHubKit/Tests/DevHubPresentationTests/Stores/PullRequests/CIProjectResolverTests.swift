import Foundation
import Testing
import DevHubDomain
import DevHubTestSupport
@testable import DevHubPresentation

@Suite struct CIProjectResolverTests {
    private let harness = StoreHarness()
    private let workflowID = "11111111-2222-3333-4444-555555555555"

    private var resolver: CIProjectResolver {
        harness.ciProjects
    }

    private func job(_ url: String) -> PipelineJob {
        PipelineJob(name: "ci/circleci: unit-tests", stage: nil, webURL: URL(string: url), id: nil, status: .failed, ciWorkflowID: workflowID)
    }

    private func resolveRemote(_ host: CodeHost) async throws {
        harness.spies.git.webURLResult = host.webURL
        _ = try await harness.codeHostRemote.codeHost()
    }

    @Test func theProviderNeedsTheCircleCIConfigFile() {
        #expect(resolver.provider == nil)
        #expect(resolver.hasProvider(for: [job("https://app.circleci.example.com/workflow/\(workflowID)/job/1")]) == false)

        harness.spies.tools.existingFiles = [CIPolicy.circleCIConfigPath(checkoutPath: harness.worktrees.mainCheckoutPath)]

        #expect(resolver.provider == .circleci)
        #expect(resolver.hasProvider(for: [job("https://app.circleci.example.com/workflow/\(workflowID)/job/1")]))
        #expect(resolver.hasProvider(for: [PipelineJob(name: "lint", stage: nil, webURL: nil, id: "9", status: .success)]) == false)
    }

    @Test func theSlugComesFromTheLinkFirst() async throws {
        try await resolveRemote(.gitHubSample)

        let project = resolver.project(for: [job("https://app.circleci.example.com/pipelines/circleci/org-1/project-2/42/workflows/\(workflowID)")])

        #expect(project == CIProject(checkoutPath: harness.worktrees.mainCheckoutPath, slug: "circleci/org-1/project-2"))
    }

    @Test func aLinkWithoutASlugFallsBackToTheGitHubRemote() async throws {
        try await resolveRemote(.gitHubSample)

        let project = resolver.project(for: [job("https://app.circleci.example.com/workflow/\(workflowID)/job/1")])

        #expect(project.slug == "gh/example/app")
    }

    @Test func aGitLabRemoteGivesNoSlug() async throws {
        try await resolveRemote(.gitLabSample)

        let project = resolver.project(for: [job("https://app.circleci.example.com/workflow/\(workflowID)/job/1")])

        #expect(project.slug == nil)
    }

    @Test func aFoundSlugIsKeptUntilTheProjectChanges() async throws {
        try await resolveRemote(.gitHubSample)
        _ = resolver.project(for: [job("https://app.circleci.example.com/pipelines/circleci/org-1/project-2/42/workflows/\(workflowID)")])

        let cached = resolver.project(for: [])
        harness.events.post(.projectChanged)
        try await resolveRemote(.gitHubSample)
        let fresh = resolver.project(for: [])

        #expect(cached.slug == "circleci/org-1/project-2")
        #expect(fresh.slug == "gh/example/app")
    }
}
