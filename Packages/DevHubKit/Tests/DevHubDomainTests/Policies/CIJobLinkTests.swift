import Foundation
import Testing
@testable import DevHubDomain

@Suite struct CIJobLinkTests {
    private let base = URL(string: "https://app.circleci.example.com")
    private let workflowID = "11111111-2222-3333-4444-555555555555"

    @Test func aGitHubSlugBecomesTheGitHubPipelinePath() {
        let url = CIJobLink.url(base: base, slug: "gh/example/app", pipelineNumber: 42, workflowID: workflowID, jobNumber: 7)

        #expect(url?.absoluteString == "https://app.circleci.example.com/pipelines/github/example/app/42/workflows/\(workflowID)/jobs/7")
    }

    @Test func theProviderOfTheSlugIsSpelledOut() {
        #expect(CIJobLink.vcsPath(slug: "gh/example/app") == "github/example/app")
        #expect(CIJobLink.vcsPath(slug: "bb/example/app") == "bitbucket/example/app")
        #expect(CIJobLink.vcsPath(slug: "circleci/ORG123/PROJ456") == "circleci/ORG123/PROJ456")
        #expect(CIJobLink.vcsPath(slug: "github/example/app") == "github/example/app")
        #expect(CIJobLink.vcsPath(slug: "example/app") == nil)
        #expect(CIJobLink.vcsPath(slug: "gh//app") == nil)
        #expect(CIJobLink.vcsPath(slug: nil) == nil)
    }

    @Test func aMissingPartGivesNoLink() {
        #expect(CIJobLink.url(base: nil, slug: "gh/example/app", pipelineNumber: 42, workflowID: workflowID, jobNumber: 7) == nil)
        #expect(CIJobLink.url(base: base, slug: nil, pipelineNumber: 42, workflowID: workflowID, jobNumber: 7) == nil)
        #expect(CIJobLink.url(base: base, slug: "gh/example/app", pipelineNumber: nil, workflowID: workflowID, jobNumber: 7) == nil)
        #expect(CIJobLink.url(base: base, slug: "gh/example/app", pipelineNumber: 42, workflowID: workflowID, jobNumber: nil) == nil)
    }

    @Test func thePipelinesPageFiltersByBranch() {
        let url = CIJobLink.pipelinesURL(base: base, slug: "gh/example/app", branch: "feature/ABC-123")

        #expect(url?.absoluteString == "https://app.circleci.example.com/pipelines/github/example/app?branch=feature/ABC-123")
        #expect(CIJobLink.pipelinesURL(base: base, slug: nil, branch: "main") == nil)
        #expect(CIJobLink.pipelinesURL(base: nil, slug: "gh/example/app", branch: "main") == nil)
    }
}
