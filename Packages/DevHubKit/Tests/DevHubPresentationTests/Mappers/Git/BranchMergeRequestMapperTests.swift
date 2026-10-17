import DevHubDomain
import DevHubUI
import Foundation
import Testing
@testable import DevHubPresentation

@Suite struct BranchMergeRequestMapperTests {
    @Test func noRequestNoModel() {
        #expect(BranchMergeRequestMapper.model(for: nil) == nil)
    }

    @Test func theTagShowsTheRequestInDevHub() throws {
        let model = try #require(BranchMergeRequestMapper.model(for: MergeRequestSummaryFixture.open))

        #expect(model.iid == 21)
        #expect(model.tag == TagModel("!21", tint: .blue, systemImage: "arrow.triangle.pull", hint: "Open merge request into dev: ABC-5: Login. Click to show it in the GitLab tab."))
        #expect(model.webURL == MergeRequestSummaryFixture.open.webURL)
        #expect(model.pipelineTag == nil)
        #expect(model.statusTags.isEmpty)
        #expect(model.linkText == "!21 ABC-5: Login\nhttps://gitlab.example.com/team/app/-/merge_requests/21")
    }

    @Test func aDraftIsGray() throws {
        let model = try #require(BranchMergeRequestMapper.model(for: MergeRequestSummaryFixture.request(iid: 3, source: "x", state: .opened, isDraft: true)))

        #expect(model.tag.text == "!3 draft")
        #expect(model.tag.tint == .gray)
    }

    @Test func pipelineApprovalAndOpenThreads() throws {
        let url = URL(string: "https://gitlab.example.com/p/9")
        let request = MergeRequestSummaryFixture.request(
            iid: 21,
            source: "x",
            state: .opened,
            pipeline: PipelineInfo(status: .success, webURL: url, updatedAt: nil),
            approvedBy: ["kim", "sam"],
            threadCount: 3,
            resolvedThreadCount: 1
        )

        let model = try #require(BranchMergeRequestMapper.model(for: request))

        #expect(model.pipelineTag == MergeRequestTagMapper.compactPipelineTag(request.pipeline!))
        #expect(model.pipelineURL == url)
        #expect(model.statusTags == [
            TagModel("approved", tint: .green, systemImage: "checkmark.seal.fill", hint: "Approved by kim, sam"),
            TagModel("2 open threads", tint: .orange, systemImage: "bubble.left.and.bubble.right", hint: "1 of 3 threads resolved, 0 comments in all"),
        ])
    }
}
