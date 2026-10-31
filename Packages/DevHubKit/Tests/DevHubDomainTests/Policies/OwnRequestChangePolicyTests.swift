import Foundation
import Testing
@testable import DevHubDomain

@Suite struct OwnRequestChangePolicyTests {
    private let username = "me"

    @Test func aNewApproverIsReportedOnMyRequestOnly() {
        let mine = request(1, approvedBy: ["alex"])
        let theirs = request(2, author: "sam", approvedBy: [])
        let after = [request(1, approvedBy: ["alex", "sam"]), request(2, author: "sam", approvedBy: ["lee"])]

        let changes = OwnRequestChangePolicy.changes(from: [mine, theirs], to: after, username: username)

        #expect(changes == [.approved(after[0], by: ["sam"])])
    }

    @Test func myOwnApprovalAndAnOldApproverAreNotReported() {
        let before = request(1, approvedBy: ["alex"])
        let after = request(1, approvedBy: ["alex", "me"])

        #expect(OwnRequestChangePolicy.changes(from: [before], to: [after], username: username).isEmpty)
    }

    @Test func aNewRequestForChangesIsReportedOnce() {
        let before = request(1)
        let after = request(1, changesRequestedBy: ["alex"])

        #expect(OwnRequestChangePolicy.changes(from: [before], to: [after], username: username) == [.changesRequested(after, by: ["alex"])])
        #expect(OwnRequestChangePolicy.changes(from: [after], to: [after], username: username).isEmpty)
        #expect(OwnRequestChangePolicy.changes(from: [before], to: [request(1, changesRequestedBy: ["me"])], username: username).isEmpty)
    }

    @Test func checksAreReportedWhenTheyStartToFail() {
        let running = request(1, pipeline: .running)
        let failed = request(1, pipeline: .failed)

        #expect(OwnRequestChangePolicy.changes(from: [running], to: [failed], username: username) == [.checksFailed(failed)])
        #expect(OwnRequestChangePolicy.changes(from: [request(1, pipeline: nil)], to: [failed], username: username) == [.checksFailed(failed)])
        #expect(OwnRequestChangePolicy.changes(from: [failed], to: [failed], username: username).isEmpty)
        #expect(OwnRequestChangePolicy.changes(from: [failed], to: [running], username: username).isEmpty)
    }

    @Test func moreCommentsAreCounted() {
        let before = request(1, comments: 2)
        let after = request(1, comments: 5)

        #expect(OwnRequestChangePolicy.changes(from: [before], to: [after], username: username) == [.newComments(after, count: 3)])
        #expect(OwnRequestChangePolicy.changes(from: [after], to: [before], username: username).isEmpty)
    }

    @Test func aRequestThatLeftTheOpenListIsGone() {
        let mine = request(1)
        let theirs = request(2, author: "sam")

        #expect(OwnRequestChangePolicy.changes(from: [mine, theirs], to: [], username: username) == [.gone(mine)])
    }

    @Test func aNewRequestOfMineIsSilent() {
        #expect(OwnRequestChangePolicy.changes(from: [], to: [request(1, approvedBy: ["alex"], comments: 3)], username: username).isEmpty)
    }

    @Test func changesOfOneRequestKeepTheirOrderAndRequestsAreSortedByNumber() {
        let before = [request(5, comments: 0), request(3, approvedBy: [])]
        let after = [request(5, pipeline: .failed, comments: 1), request(3, approvedBy: ["alex"])]

        let changes = OwnRequestChangePolicy.changes(from: before, to: after, username: username)

        #expect(changes == [.approved(after[1], by: ["alex"]), .checksFailed(after[0]), .newComments(after[0], count: 1)])
    }

    private func request(_ iid: Int, author: String = "me", approvedBy: [String] = [], changesRequestedBy: [String] = [], pipeline: CheckStatus? = nil, comments: Int = 0) -> PullRequestSummary {
        PullRequestSummary(
            iid: iid,
            title: "ABC-\(iid): Change",
            state: .opened,
            isDraft: false,
            webURL: nil,
            author: author,
            sourceBranch: "feature/ABC-\(iid)",
            targetBranch: "main",
            hasConflicts: false,
            detailedStatus: nil,
            commentCount: comments,
            updatedAt: nil,
            pipeline: pipeline.map { PipelineInfo(status: $0, webURL: nil, updatedAt: nil) },
            approvedBy: approvedBy,
            labels: [],
            changesRequestedBy: changesRequestedBy
        )
    }
}
