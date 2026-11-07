import DevHubDomain
import DevHubUI
import Foundation
import Testing
@testable import DevHubPresentation

@Suite struct PullRequestActionMapperTests {
    @Test func aRequestThatNeedsMyReviewShowsApproveOnHover() {
        let request = PullRequestSummaryFixture.request(iid: 7, source: "x", state: .opened)

        #expect(PullRequestActionMapper.primary(for: request, reviewer: ReviewerIdentity(username: "me"), words: .gitLab).map(\.id) == [.approve])
        #expect(PullRequestActionMapper.primary(for: request, reviewer: ReviewerIdentity(username: "me"), words: .gitLab).first?.tint == .green)
        #expect(PullRequestActionMapper.overflow(for: request, reviewer: ReviewerIdentity(username: "me"), words: .gitLab).map(\.id) == [.markDraft, .rebase])
        #expect(PullRequestActionMapper.overflow(for: request, reviewer: ReviewerIdentity(username: "me"), words: .gitLab)[1].title == "Rebase onto dev")
    }

    @Test func approveNeedsThePermission() {
        let request = PullRequestSummaryFixture.request(iid: 7, source: "x", state: .opened, permissions: PullRequestPermissions(canMerge: true, canApprove: false, canRevokeApproval: true, canSetAutoMerge: true))

        #expect(PullRequestActionMapper.primary(for: request, reviewer: ReviewerIdentity(username: "me"), words: .gitLab).isEmpty)
        #expect(PullRequestActionMapper.overflow(for: request, reviewer: ReviewerIdentity(username: "me"), words: .gitLab).map(\.id) == [.markDraft, .rebase])
    }

    @Test func aDraftByAnotherAuthorKeepsApproveInTheMenu() {
        let draft = PullRequestSummaryFixture.request(iid: 7, source: "x", state: .opened, isDraft: true)

        #expect(PullRequestActionMapper.primary(for: draft, reviewer: ReviewerIdentity(username: "me"), words: .gitLab).isEmpty)
        #expect(PullRequestActionMapper.overflow(for: draft, reviewer: ReviewerIdentity(username: "me"), words: .gitLab).map(\.id) == [.approve, .markReady, .rebase])
    }

    @Test func myApprovalCanBeRevokedAndMyOwnRequestHasNoApproval() {
        let approved = PullRequestSummaryFixture.request(iid: 7, source: "x", state: .opened, approvedBy: ["me"])
        let mine = PullRequestSummaryFixture.request(iid: 7, source: "x", state: .opened, author: "me")

        #expect(PullRequestActionMapper.primary(for: approved, reviewer: ReviewerIdentity(username: "me"), words: .gitLab).isEmpty)
        #expect(PullRequestActionMapper.overflow(for: approved, reviewer: ReviewerIdentity(username: "me"), words: .gitLab).first?.id == .unapprove)
        #expect(PullRequestActionMapper.overflow(for: mine, reviewer: ReviewerIdentity(username: "me"), words: .gitLab).map(\.id) == [.markDraft, .rebase])
        #expect(PullRequestActionMapper.overflow(for: mine, reviewer: nil, words: .gitLab).map(\.id) == [.markDraft, .rebase])
        #expect(PullRequestActionMapper.primary(for: mine, reviewer: nil, words: .gitLab).isEmpty)
    }

    @Test func pipelineRetryStaysInTheMenu() {
        let failed = PullRequestSummaryFixture.request(iid: 7, source: "x", state: .opened, author: "me", pipeline: PipelineInfo(status: .failed, webURL: nil, updatedAt: nil, id: 9))
        let failedWithoutID = PullRequestSummaryFixture.request(iid: 7, source: "x", state: .opened, author: "me", pipeline: PipelineInfo(status: .failed, webURL: nil, updatedAt: nil))

        #expect(PullRequestActionMapper.overflow(for: failed, reviewer: ReviewerIdentity(username: "me"), words: .gitLab).map(\.id) == [.markDraft, .rebase, .retryPipeline])
        #expect(PullRequestActionMapper.overflow(for: failedWithoutID, reviewer: ReviewerIdentity(username: "me"), words: .gitLab).map(\.id) == [.markDraft, .rebase])
    }

    @Test func mergeIsShownOnHoverWhenMergeableAndAllowed() {
        let mergeable = PullRequestSummaryFixture.request(iid: 7, source: "x", state: .opened, author: "me", detail: .mergeable)
        let forbidden = PullRequestSummaryFixture.request(iid: 7, source: "x", state: .opened, author: "me", detail: .mergeable, permissions: PullRequestPermissions(canMerge: false, canApprove: true, canRevokeApproval: true, canSetAutoMerge: false))

        #expect(PullRequestActionMapper.primary(for: mergeable, reviewer: ReviewerIdentity(username: "me"), words: .gitLab).map(\.id) == [.merge])
        #expect(PullRequestActionMapper.primary(for: mergeable, reviewer: ReviewerIdentity(username: "me"), words: .gitLab).first?.tint == .purple)
        #expect(PullRequestActionMapper.overflow(for: mergeable, reviewer: ReviewerIdentity(username: "me"), words: .gitLab).contains { $0.id == .merge } == false)
        #expect(PullRequestActionMapper.primary(for: forbidden, reviewer: ReviewerIdentity(username: "me"), words: .gitLab).isEmpty)
    }

    @Test func approveComesBeforeMerge() {
        let request = PullRequestSummaryFixture.request(iid: 7, source: "x", state: .opened, detail: .mergeable)

        #expect(PullRequestActionMapper.primary(for: request, reviewer: ReviewerIdentity(username: "me"), words: .gitLab).map(\.id) == [.approve, .merge])
    }

    @Test func closedAndMergedRequestsHaveNoActions() {
        for state in [PullRequestState.merged, .closed] {
            let request = PullRequestSummaryFixture.request(iid: 7, source: "x", state: state, detail: .mergeable)
            #expect(PullRequestActionMapper.primary(for: request, reviewer: ReviewerIdentity(username: "me"), words: .gitLab).isEmpty)
            #expect(PullRequestActionMapper.overflow(for: request, reviewer: ReviewerIdentity(username: "me"), words: .gitLab).isEmpty)
        }
    }

    @Test func aRunningPipelineOffersAutoMerge() {
        let running = PullRequestSummaryFixture.request(iid: 7, source: "x", state: .opened, author: "me", detail: .ciStillRunning)
        let forbidden = PullRequestSummaryFixture.request(iid: 7, source: "x", state: .opened, author: "me", detail: .ciStillRunning, permissions: PullRequestPermissions(canMerge: false, canApprove: true, canRevokeApproval: true, canSetAutoMerge: false))

        #expect(PullRequestActionMapper.primary(for: running, reviewer: ReviewerIdentity(username: "me"), words: .gitLab).map(\.id) == [.mergeWhenPipelinePasses])
        #expect(PullRequestActionMapper.primary(for: running, reviewer: ReviewerIdentity(username: "me"), words: .gitLab).first?.tint == .purple)
        #expect(PullRequestActionMapper.primary(for: forbidden, reviewer: ReviewerIdentity(username: "me"), words: .gitLab).isEmpty)
    }

    @Test func autoMergeTurnsIntoCancel() {
        let request = PullRequestSummaryFixture.request(iid: 7, source: "x", state: .opened, author: "me", detail: .ciStillRunning, isAutoMergeEnabled: true)

        #expect(PullRequestActionMapper.primary(for: request, reviewer: ReviewerIdentity(username: "me"), words: .gitLab).isEmpty)
        #expect(PullRequestActionMapper.overflow(for: request, reviewer: ReviewerIdentity(username: "me"), words: .gitLab).map(\.id) == [.markDraft, .rebase, .cancelAutoMerge])
    }

    @Test func anActivePipelineCanBeCancelled() {
        let running = PullRequestSummaryFixture.request(iid: 7, source: "x", state: .opened, author: "me", pipeline: PipelineInfo(status: .running, webURL: nil, updatedAt: nil, id: 9))
        let noID = PullRequestSummaryFixture.request(iid: 7, source: "x", state: .opened, author: "me", pipeline: PipelineInfo(status: .pending, webURL: nil, updatedAt: nil))

        #expect(PullRequestActionMapper.overflow(for: running, reviewer: ReviewerIdentity(username: "me"), words: .gitLab).map(\.id) == [.markDraft, .rebase, .cancelPipeline])
        #expect(PullRequestActionMapper.overflow(for: noID, reviewer: ReviewerIdentity(username: "me"), words: .gitLab).map(\.id) == [.markDraft, .rebase])
    }
}
