import Testing
@testable import DevHubDomain

@Suite struct CIWorkflowLinkTests {
    private let workflowID = "11111111-2222-3333-4444-555555555555"

    @Test func aGitHubAppLinkGivesTheWorkflowAndTheCircleCISlug() {
        let link = CIWorkflowLink.parse("https://app.circleci.example.com/pipelines/circleci/ABCDEFGH1234567890abcdef/XYZ0123456789abcdefghij/42/workflows/\(workflowID)")

        #expect(link == CIWorkflowLink.Link(workflowID: workflowID, slug: "circleci/ABCDEFGH1234567890abcdef/XYZ0123456789abcdefghij"))
    }

    @Test func anOAuthJobLinkGivesTheWorkflowAndTheGitHubSlug() {
        let link = CIWorkflowLink.parse("https://app.circleci.example.com/pipelines/github/example/app/42/workflows/\(workflowID)/jobs/7?utm_campaign=vcs-integration-link")

        #expect(link == CIWorkflowLink.Link(workflowID: workflowID, slug: "gh/example/app"))
    }

    @Test func aQueryStringAfterTheWorkflowIsIgnored() {
        let link = CIWorkflowLink.parse("https://app.circleci.example.com/pipelines/github/example/app/42/workflows/\(workflowID)?x=1")

        #expect(link?.workflowID == workflowID)
    }

    @Test func otherLinksAreNotCircleCI() {
        #expect(CIWorkflowLink.parse("https://github.com/example/app/actions/runs/903/job/9031") == nil)
        #expect(CIWorkflowLink.parse("https://app.circleci.example.com/pipelines/github/example/app/42") == nil)
        #expect(CIWorkflowLink.parse("https://app.circleci.example.com/pipelines/github/example/app/42/workflows/not-a-uuid") == nil)
        #expect(CIWorkflowLink.parse(nil) == nil)
    }

    @Test func aLinkWithoutAProjectHasNoSlug() {
        let link = CIWorkflowLink.parse("https://app.circleci.example.com/workflows/\(workflowID)")

        #expect(link == CIWorkflowLink.Link(workflowID: workflowID, slug: nil))
    }
}
