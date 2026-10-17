import DevHubDomain
import Foundation
import Testing
@testable import DevHubData

@Suite struct GlabPullRequestParserTests {
    @Test func picksTheFirstOpenedMergeRequest() throws {
        let request = try #require(try GlabPullRequestParser.mergeRequest(from: GlabFixture.mergeRequests))

        #expect(request == PullRequestInfo(
            iid: 12,
            title: "ABC-1: Open MR",
            state: .opened,
            isDraft: true,
            webURL: URL(string: "https://gitlab.com/group/app/-/merge_requests/12"),
            author: "sam",
            hasConflicts: true,
            detailedStatus: .needRebase,
            targetBranch: "main"
        ))
    }

    @Test func fallsBackToTheFirstWhenNoneIsOpened() throws {
        let request = try #require(try GlabPullRequestParser.mergeRequest(from: GlabFixture.closedMergeRequests))

        #expect(request.iid == 3)
        #expect(request.state == .closed)
        #expect(request.isDraft == false)
        #expect(request.webURL == nil)
        #expect(request.author == "")
        #expect(request.hasConflicts == false)
        #expect(request.detailedStatus == nil)
    }

    @Test func emptyListHasNoMergeRequest() throws {
        #expect(try GlabPullRequestParser.mergeRequest(from: GlabFixture.empty) == nil)
    }

    @Test(arguments: [
        ("opened", PullRequestState.opened),
        ("merged", .merged),
        ("closed", .closed),
        ("locked", .locked),
        ("reopened", .other("reopened")),
    ])
    func mapsState(name: String, expected: PullRequestState) throws {
        let request = try GlabPullRequestParser.mergeRequest(from: GlabFixture.mergeRequest(state: name, detail: "mergeable"))
        #expect(request?.state == expected)
    }

    @Test(arguments: [
        ("mergeable", MergeDetail.mergeable),
        ("not_approved", .notApproved),
        ("ci_must_pass", .ciMustPass),
        ("ci_still_running", .ciStillRunning),
        ("discussions_not_resolved", .discussionsNotResolved),
        ("need_rebase", .needRebase),
        ("draft_status", .draftStatus),
        ("blocked_status", .other("blocked_status")),
    ])
    func mapsDetail(name: String, expected: MergeDetail) throws {
        let request = try GlabPullRequestParser.mergeRequest(from: GlabFixture.mergeRequest(state: "opened", detail: name))
        #expect(request?.detailedStatus == expected)
    }

    @Test func readsTheFirstPipeline() throws {
        let pipeline = try #require(try GlabPullRequestParser.pipeline(from: GlabFixture.pipelines))

        #expect(pipeline.status == .running)
        #expect(pipeline.webURL == URL(string: "https://gitlab.com/group/app/-/pipelines/99"))
        #expect(pipeline.updatedAt == Date(timeIntervalSince1970: 1_767_323_045))
    }

    @Test func unreadableDateFallsBackToDistantPast() throws {
        let pipeline = try GlabPullRequestParser.pipeline(from: GlabFixture.pipelineWithBadDate)
        #expect(pipeline?.updatedAt == .distantPast)
    }

    @Test func missingDateIsNil() throws {
        let pipeline = try #require(try GlabPullRequestParser.pipeline(from: GlabFixture.pipelineWithoutDate))
        #expect(pipeline.updatedAt == nil)
        #expect(pipeline.webURL == nil)
    }

    @Test func emptyListHasNoPipeline() throws {
        #expect(try GlabPullRequestParser.pipeline(from: GlabFixture.empty) == nil)
    }

    @Test(arguments: [
        ("success", PipelineStatus.success),
        ("failed", .failed),
        ("running", .running),
        ("pending", .pending),
        ("created", .created),
        ("waiting_for_resource", .waitingForResource),
        ("preparing", .preparing),
        ("scheduled", .scheduled),
        ("canceled", .canceled),
        ("skipped", .skipped),
        ("manual", .manual),
        ("canceling", .other("canceling")),
    ])
    func mapsPipelineStatus(name: String, expected: PipelineStatus) throws {
        let pipeline = try GlabPullRequestParser.pipeline(from: GlabFixture.pipeline(status: name))
        #expect(pipeline?.status == expected)
    }

    @Test func malformedMergeRequestsThrowCommandError() throws {
        let error = try #require(throws: PullRequestError.self) {
            try GlabPullRequestParser.mergeRequest(from: GlabFixture.malformed)
        }
        guard case .command(let message) = error else {
            Issue.record("Expected .command, got \(error)")
            return
        }
        #expect(message.hasPrefix("Unexpected answer from GitLab: "))
    }

    @Test func malformedPipelinesThrowCommandError() {
        #expect(throws: PullRequestError.self) {
            try GlabPullRequestParser.pipeline(from: Data("not json".utf8))
        }
    }
}
