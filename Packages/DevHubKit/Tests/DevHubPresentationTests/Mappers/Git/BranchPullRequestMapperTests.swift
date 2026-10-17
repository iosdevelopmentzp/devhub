import DevHubDomain
import DevHubUI
import Foundation
import Testing
@testable import DevHubPresentation

@Suite struct BranchPullRequestMapperTests {
    @Test func noRequestNoModel() {
        #expect(BranchPullRequestMapper.model(for: nil, words: .gitLab) == nil)
    }

    @Test func theTagShowsTheRequestInDevHub() throws {
        let model = try #require(BranchPullRequestMapper.model(for: PullRequestSummaryFixture.open, words: .gitLab))

        #expect(model.iid == 21)
        #expect(model.tag == TagModel("!21", tint: .blue, systemImage: "arrow.triangle.pull", hint: "Open merge request into dev: ABC-5: Login. Click to show it in the Merge Requests tab."))
        #expect(model.webURL == PullRequestSummaryFixture.open.webURL)
        #expect(model.pipelineTag == nil)
        #expect(model.statusTags.isEmpty)
        #expect(model.linkText == "!21 ABC-5: Login\nhttps://gitlab.example.com/team/app/-/merge_requests/21")
    }

    @Test func aDraftIsGray() throws {
        let model = try #require(BranchPullRequestMapper.model(for: PullRequestSummaryFixture.request(iid: 3, source: "x", state: .opened, isDraft: true), words: .gitLab))

        #expect(model.tag.text == "!3 draft")
        #expect(model.tag.tint == .gray)
    }

    @Test func pipelineApprovalAndOpenThreads() throws {
        let url = URL(string: "https://gitlab.example.com/p/9")
        let request = PullRequestSummaryFixture.request(
            iid: 21,
            source: "x",
            state: .opened,
            pipeline: PipelineInfo(status: .success, webURL: url, updatedAt: nil),
            approvedBy: ["kim", "sam"],
            threadCount: 3,
            resolvedThreadCount: 1
        )

        let model = try #require(BranchPullRequestMapper.model(for: request, words: .gitLab))

        #expect(model.pipelineTag == PullRequestTagMapper.compactPipelineTag(request.pipeline!, words: .gitLab))
        #expect(model.pipelineURL == url)
        #expect(model.statusTags == [
            TagModel("approved", tint: .green, systemImage: "checkmark.seal.fill", hint: "Approved by kim, sam"),
            TagModel("2 open threads", tint: .orange, systemImage: "bubble.left.and.bubble.right", hint: "1 of 3 threads resolved, 0 comments in all"),
        ])
    }
}
