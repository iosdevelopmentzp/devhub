import DevHubDomain
import DevHubUI
import Foundation
import Testing
@testable import DevHubPresentation

@Suite struct PullRequestGitHubWordsTests {
    private let readOnly = PullRequestPermissions(canMerge: false, canApprove: true, canRevokeApproval: false, canSetAutoMerge: false)

    @Test func gitHubActionsUseGitHubWords() {
        let request = PullRequestSummaryFixture.request(iid: 7, source: "x", state: .opened, pipeline: PipelineInfo(status: .failed, webURL: nil, updatedAt: nil, id: 90))

        let overflow = PullRequestActionMapper.overflow(for: request, username: "me", words: .gitHub)

        #expect(overflow.map(\.title) == ["Mark as Draft", "Update Branch from dev", "Re-run Failed Checks"])
        #expect(overflow[1].hint == "GitHub merges dev into the source branch on the server. Fails on conflicts.")
    }

    @Test func revokeNeedsThePermission() {
        let approved = PullRequestSummaryFixture.request(iid: 7, source: "x", state: .opened, approvedBy: ["me"], permissions: readOnly)

        #expect(PullRequestActionMapper.overflow(for: approved, username: "me", words: .gitHub).contains { $0.id == .unapprove } == false)
    }

    @Test func autoMergeNeedsThePermission() {
        let running = PullRequestSummaryFixture.request(iid: 7, source: "x", state: .opened, author: "me", detail: .ciStillRunning, permissions: readOnly)
        let allowed = PullRequestSummaryFixture.request(iid: 7, source: "x", state: .opened, author: "me", detail: .ciStillRunning)

        #expect(PullRequestActionMapper.primary(for: running, username: "me", words: .gitHub).isEmpty)
        #expect(PullRequestActionMapper.primary(for: allowed, username: "me", words: .gitHub).map(\.title) == ["Merge When Checks Pass…"])
    }

    @Test func tagsAndReferencesUseTheHashSign() throws {
        let request = PullRequestSummaryFixture.request(iid: 3, source: "x", state: .opened, pipeline: PipelineInfo(status: .failed, webURL: nil, updatedAt: nil, failedJobCount: 2))

        let pipeline = try #require(request.pipeline)

        #expect(PullRequestTagMapper.compactPipelineTag(pipeline, words: .gitHub) == TagModel("checks failed", tint: .red, systemImage: "xmark.circle.fill", hint: "2 checks failed. Click to open it."))
        #expect(RequestLinkText.pullRequest(iid: 3, title: "Fix", url: nil, words: .gitHub) == "#3 Fix")
        #expect(BranchPullRequestMapper.model(for: request, words: .gitHub)?.tag.text == "#3")
    }
}
