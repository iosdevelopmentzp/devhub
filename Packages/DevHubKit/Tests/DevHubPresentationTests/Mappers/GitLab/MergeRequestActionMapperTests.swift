import DevHubDomain
import DevHubUI
import Foundation
import Testing
@testable import DevHubPresentation

@Suite struct MergeRequestActionMapperTests {
    @Test func aRequestThatNeedsMyReviewShowsApproveOnHover() {
        let request = MergeRequestSummaryFixture.request(iid: 7, source: "x", state: .opened)

        #expect(MergeRequestActionMapper.primary(for: request, username: "me").map(\.id) == [.approve])
        #expect(MergeRequestActionMapper.primary(for: request, username: "me").first?.tint == .green)
        #expect(MergeRequestActionMapper.overflow(for: request, username: "me").map(\.id) == [.markDraft, .rebase])
        #expect(MergeRequestActionMapper.overflow(for: request, username: "me")[1].title == "Rebase onto dev")
    }

    @Test func approveNeedsThePermission() {
        let request = MergeRequestSummaryFixture.request(iid: 7, source: "x", state: .opened, permissions: MergeRequestPermissions(canMerge: true, canApprove: false))

        #expect(MergeRequestActionMapper.primary(for: request, username: "me").isEmpty)
        #expect(MergeRequestActionMapper.overflow(for: request, username: "me").map(\.id) == [.markDraft, .rebase])
    }

    @Test func aDraftByAnotherAuthorKeepsApproveInTheMenu() {
        let draft = MergeRequestSummaryFixture.request(iid: 7, source: "x", state: .opened, isDraft: true)

        #expect(MergeRequestActionMapper.primary(for: draft, username: "me").isEmpty)
        #expect(MergeRequestActionMapper.overflow(for: draft, username: "me").map(\.id) == [.approve, .markReady, .rebase])
    }

    @Test func myApprovalCanBeRevokedAndMyOwnRequestHasNoApproval() {
        let approved = MergeRequestSummaryFixture.request(iid: 7, source: "x", state: .opened, approvedBy: ["me"])
        let mine = MergeRequestSummaryFixture.request(iid: 7, source: "x", state: .opened, author: "me")

        #expect(MergeRequestActionMapper.primary(for: approved, username: "me").isEmpty)
        #expect(MergeRequestActionMapper.overflow(for: approved, username: "me").first?.id == .unapprove)
        #expect(MergeRequestActionMapper.overflow(for: mine, username: "me").map(\.id) == [.markDraft, .rebase])
        #expect(MergeRequestActionMapper.overflow(for: mine, username: nil).map(\.id) == [.markDraft, .rebase])
        #expect(MergeRequestActionMapper.primary(for: mine, username: nil).isEmpty)
    }

    @Test func pipelineRetryStaysInTheMenu() {
        let failed = MergeRequestSummaryFixture.request(iid: 7, source: "x", state: .opened, author: "me", pipeline: PipelineInfo(status: .failed, webURL: nil, updatedAt: nil, id: 9))
        let failedWithoutID = MergeRequestSummaryFixture.request(iid: 7, source: "x", state: .opened, author: "me", pipeline: PipelineInfo(status: .failed, webURL: nil, updatedAt: nil))

        #expect(MergeRequestActionMapper.overflow(for: failed, username: "me").map(\.id) == [.markDraft, .rebase, .retryPipeline])
        #expect(MergeRequestActionMapper.overflow(for: failedWithoutID, username: "me").map(\.id) == [.markDraft, .rebase])
    }

    @Test func mergeIsShownOnHoverWhenMergeableAndAllowed() {
        let mergeable = MergeRequestSummaryFixture.request(iid: 7, source: "x", state: .opened, author: "me", detail: .mergeable)
        let forbidden = MergeRequestSummaryFixture.request(iid: 7, source: "x", state: .opened, author: "me", detail: .mergeable, permissions: MergeRequestPermissions(canMerge: false, canApprove: true))

        #expect(MergeRequestActionMapper.primary(for: mergeable, username: "me").map(\.id) == [.merge])
        #expect(MergeRequestActionMapper.primary(for: mergeable, username: "me").first?.tint == .purple)
        #expect(MergeRequestActionMapper.overflow(for: mergeable, username: "me").contains { $0.id == .merge } == false)
        #expect(MergeRequestActionMapper.primary(for: forbidden, username: "me").isEmpty)
    }

    @Test func approveComesBeforeMerge() {
        let request = MergeRequestSummaryFixture.request(iid: 7, source: "x", state: .opened, detail: .mergeable)

        #expect(MergeRequestActionMapper.primary(for: request, username: "me").map(\.id) == [.approve, .merge])
    }

    @Test func closedAndMergedRequestsHaveNoActions() {
        for state in [MergeRequestState.merged, .closed] {
            let request = MergeRequestSummaryFixture.request(iid: 7, source: "x", state: state, detail: .mergeable)
            #expect(MergeRequestActionMapper.primary(for: request, username: "me").isEmpty)
            #expect(MergeRequestActionMapper.overflow(for: request, username: "me").isEmpty)
        }
    }

    @Test func aRunningPipelineOffersAutoMerge() {
        let running = MergeRequestSummaryFixture.request(iid: 7, source: "x", state: .opened, author: "me", detail: .ciStillRunning)
        let forbidden = MergeRequestSummaryFixture.request(iid: 7, source: "x", state: .opened, author: "me", detail: .ciStillRunning, permissions: MergeRequestPermissions(canMerge: false, canApprove: true))

        #expect(MergeRequestActionMapper.primary(for: running, username: "me").map(\.id) == [.mergeWhenPipelinePasses])
        #expect(MergeRequestActionMapper.primary(for: running, username: "me").first?.tint == .purple)
        #expect(MergeRequestActionMapper.primary(for: forbidden, username: "me").isEmpty)
    }

    @Test func autoMergeTurnsIntoCancel() {
        let request = MergeRequestSummaryFixture.request(iid: 7, source: "x", state: .opened, author: "me", detail: .ciStillRunning, isAutoMergeEnabled: true)

        #expect(MergeRequestActionMapper.primary(for: request, username: "me").isEmpty)
        #expect(MergeRequestActionMapper.overflow(for: request, username: "me").map(\.id) == [.markDraft, .rebase, .cancelAutoMerge])
    }

    @Test func anActivePipelineCanBeCancelled() {
        let running = MergeRequestSummaryFixture.request(iid: 7, source: "x", state: .opened, author: "me", pipeline: PipelineInfo(status: .running, webURL: nil, updatedAt: nil, id: 9))
        let noID = MergeRequestSummaryFixture.request(iid: 7, source: "x", state: .opened, author: "me", pipeline: PipelineInfo(status: .pending, webURL: nil, updatedAt: nil))

        #expect(MergeRequestActionMapper.overflow(for: running, username: "me").map(\.id) == [.markDraft, .rebase, .cancelPipeline])
        #expect(MergeRequestActionMapper.overflow(for: noID, username: "me").map(\.id) == [.markDraft, .rebase])
    }
}
