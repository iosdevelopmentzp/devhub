import DevHubDomain
import DevHubUI
import Foundation
import Testing
@testable import DevHubPresentation

@Suite struct MergeRequestTagMapperTests {
    @Test func aPassedPipelineIsAnIconOnlyGreenTag() {
        let tag = MergeRequestTagMapper.compactPipelineTag(PipelineInfo(status: .success, webURL: nil, updatedAt: nil))

        #expect(tag == .icon("checkmark.circle.fill", tint: .green, hint: "Pipeline passed. Click to open it."))
    }

    @Test(arguments: [
        (PipelineStatus.running, "running", Tint.blue),
        (.pending, "pending", .orange),
        (.created, "pending", .orange),
        (.failed, "pipeline failed", .red),
        (.canceled, "pipeline canceled", .secondary),
    ])
    func everyPipelineStatusHasATag(status: PipelineStatus, text: String, tint: Tint) {
        let tag = MergeRequestTagMapper.compactPipelineTag(PipelineInfo(status: status, webURL: nil, updatedAt: nil))

        #expect(tag.text == text)
        #expect(tag.tint == tint)
    }

    @Test func aFailedPipelineCountsTheFailedJobs() {
        let failed = PipelineInfo(status: .failed, webURL: nil, updatedAt: nil, failedJobCount: 2)
        let unknown = PipelineInfo(status: .failed, webURL: nil, updatedAt: nil)

        #expect(MergeRequestTagMapper.compactPipelineTag(failed).hint == "2 jobs failed. Click to open it.")
        #expect(MergeRequestTagMapper.compactPipelineTag(unknown).hint == "Pipeline failed. Click to open it.")
    }

    @Test(arguments: [
        (["kim"], "approved by kim"),
        (["kim", "sam"], "approved by kim, sam"),
        (["kim", "sam", "robin"], "approved by kim +2"),
        (["kim", "me"], "you approved"),
    ])
    func approvalsNameThePeople(names: [String], text: String) {
        #expect(MergeRequestTagMapper.approvalTag(approvedBy: names, username: "me")?.text == text)
    }

    @Test func approvalHintListsEveryName() {
        let tag = MergeRequestTagMapper.approvalTag(approvedBy: ["kim", "me", "sam"], username: "me")

        #expect(tag?.hint == "Approved by kim, you, sam")
        #expect(MergeRequestTagMapper.approvalTag(approvedBy: [], username: "me") == nil)
    }

    @Test func openThreadsCountOnlyUnresolvedOnes() {
        let tag = MergeRequestTagMapper.openThreadsTag(open: 3, total: 5, comments: 12)

        #expect(tag == TagModel("3 open threads", tint: .orange, systemImage: "bubble.left.and.bubble.right", hint: "2 of 5 threads resolved, 12 comments in all"))
        #expect(MergeRequestTagMapper.openThreadsTag(open: 1, total: 1, comments: 1)?.text == "1 open thread")
        #expect(MergeRequestTagMapper.openThreadsTag(open: 0, total: 4, comments: 9) == nil)
    }

    @Test func behindNamesTheTarget() {
        let tag = MergeRequestTagMapper.behindTag(targetBranch: "dev")

        #expect(tag.text == "behind dev")
        #expect(tag.tint == .orange)
        #expect(tag.hint == "The source branch is behind dev. Rebase brings it up to date")
    }
}
