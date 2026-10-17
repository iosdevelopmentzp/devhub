import DevHubDomain
import DevHubUI
import Foundation
import Testing
@testable import DevHubPresentation

@Suite struct MergeRequestLineMapperTests {
    @Test func notLoggedInShowsTheLoginCommand() {
        let model = MergeRequestLineMapper.model(status: nil, error: .notLoggedIn(host: "gitlab.example.com"), isLoading: false, openRequest: nil, username: nil)

        #expect(model.content == .notConnected(loginCommand: "glab auth login --hostname gitlab.example.com"))
        #expect(model.canRefresh)
        #expect(model.isLoading == false)
    }

    @Test func otherErrorsShowTheirDescription() {
        let notGitLab = MergeRequestLineMapper.model(status: nil, error: .notGitLab, isLoading: false, openRequest: nil, username: nil)
        let notInstalled = MergeRequestLineMapper.model(status: nil, error: .notInstalled, isLoading: true, openRequest: nil, username: nil)
        let command = MergeRequestLineMapper.model(status: nil, error: .command("HTTP 500"), isLoading: false, openRequest: nil, username: nil)

        #expect(notGitLab.content == .failure("The remote is not on GitLab"))
        #expect(notGitLab.canRefresh == false)
        #expect(notInstalled.content == .failure("glab is not installed. brew install glab"))
        #expect(notInstalled.canRefresh)
        #expect(notInstalled.isLoading)
        #expect(command.content == .failure("HTTP 500"))
    }

    @Test func errorWinsOverStatus() {
        let status = MergeRequestStatus(mergeRequest: nil, pipeline: nil)

        #expect(MergeRequestLineMapper.model(status: status, error: .command("x"), isLoading: false, openRequest: nil, username: nil).content == .failure("x"))
    }

    @Test func noStatusYetIsChecking() {
        #expect(MergeRequestLineMapper.model(status: nil, error: nil, isLoading: true, openRequest: nil, username: nil).content == .checking)
    }

    @Test func noMergeRequestAndNoPipeline() {
        let model = MergeRequestLineMapper.model(status: MergeRequestStatus(mergeRequest: nil, pipeline: nil), error: nil, isLoading: false, openRequest: nil, username: nil)

        #expect(model.content == .status(MergeRequestLineModel.Status(
            requestTag: nil,
            requestURL: nil,
            requestTags: [],
            placeholder: "No merge request yet",
            pipelineTag: nil,
            pipelineURL: nil
        )))
    }

    @Test func openRequestTag() throws {
        let status = try mapStatus(request: MergeRequestFixture.request(state: .opened, isDraft: false, hasConflicts: false, detail: nil), pipeline: nil)

        #expect(status.requestTag == TagModel(
            "!12 open",
            tint: .blue,
            systemImage: "arrow.triangle.pull",
            hint: "ABC-1: Login screen\nby alex into dev. Click to show it in the GitLab tab."
        ))
        #expect(status.requestURL == MergeRequestFixture.url)
        #expect(status.requestTags.isEmpty)
        #expect(status.placeholder == nil)
    }

    @Test func requestTitleAndTintPerState() throws {
        let table: [(MergeRequestState, Bool, String, Tint)] = [
            (.opened, false, "!12 open", .blue),
            (.opened, true, "!12 draft", .gray),
            (.merged, false, "!12 merged", .purple),
            (.merged, true, "!12 merged", .purple),
            (.closed, false, "!12 closed", .secondary),
            (.locked, false, "!12 locked", .blue),
            (.locked, true, "!12 locked", .gray),
            (.other("archived"), false, "!12 archived", .blue)
        ]

        for (state, isDraft, text, tint) in table {
            let status = try mapStatus(request: MergeRequestFixture.request(state: state, isDraft: isDraft, hasConflicts: false, detail: nil), pipeline: nil)
            #expect(status.requestTag?.text == text)
            #expect(status.requestTag?.tint == tint)
        }
    }

    @Test func conflictsTag() throws {
        let status = try mapStatus(request: MergeRequestFixture.request(state: .opened, isDraft: false, hasConflicts: true, detail: nil), pipeline: nil)

        #expect(status.requestTags == [TagModel(
            "conflicts",
            tint: .red,
            systemImage: "exclamationmark.triangle.fill",
            hint: "GitLab cannot merge it: rebase on dev and solve the conflicts"
        )])
    }

    @Test func detailTagForOpenRequests() throws {
        let table: [(MergeDetail, TagModel?)] = [
            (.mergeable, TagModel("ready to merge", tint: .green, hint: "GitLab merge status: mergeable")),
            (.notApproved, TagModel("needs approval", tint: .orange, hint: "GitLab merge status: not_approved")),
            (.ciMustPass, TagModel("waiting for CI", tint: .blue, hint: "GitLab merge status: ci_must_pass")),
            (.ciStillRunning, TagModel("waiting for CI", tint: .blue, hint: "GitLab merge status: ci_still_running")),
            (.discussionsNotResolved, TagModel("open threads", tint: .orange, hint: "GitLab merge status: discussions_not_resolved")),
            (.needRebase, TagModel("needs rebase", tint: .orange, hint: "GitLab merge status: need_rebase")),
            (.draftStatus, nil),
            (.other("blocked_status"), TagModel("blocked status", tint: .secondary, hint: "GitLab merge status: blocked_status"))
        ]

        for (detail, tag) in table {
            let status = try mapStatus(request: MergeRequestFixture.request(state: .opened, isDraft: false, hasConflicts: false, detail: detail), pipeline: nil)
            #expect(status.requestTags == (tag.map { [$0] } ?? []))
        }
    }

    @Test func detailIsIgnoredWhenNotOpen() throws {
        let status = try mapStatus(request: MergeRequestFixture.request(state: .merged, isDraft: false, hasConflicts: false, detail: .mergeable), pipeline: nil)

        #expect(status.requestTags.isEmpty)
    }

    @Test func conflictsComeBeforeTheDetail() throws {
        let status = try mapStatus(request: MergeRequestFixture.request(state: .opened, isDraft: false, hasConflicts: true, detail: .needRebase), pipeline: nil)

        #expect(status.requestTags.map(\.text) == ["conflicts", "needs rebase"])
    }

    @Test func pipelineTagPerStatus() throws {
        let table: [(PipelineStatus, Tint, String)] = [
            (.success, .green, "checkmark.circle.fill"),
            (.failed, .red, "xmark.circle.fill"),
            (.running, .blue, "play.circle.fill"),
            (.pending, .orange, "clock"),
            (.created, .orange, "clock"),
            (.waitingForResource, .orange, "clock"),
            (.preparing, .orange, "clock"),
            (.scheduled, .orange, "clock"),
            (.canceled, .secondary, "slash.circle"),
            (.skipped, .secondary, "slash.circle"),
            (.manual, .secondary, "clock"),
            (.other("unknown"), .secondary, "clock")
        ]

        for (pipelineStatus, tint, icon) in table {
            let status = try mapStatus(request: nil, pipeline: MergeRequestFixture.pipeline(pipelineStatus))
            #expect(status.pipelineTag == TagModel(
                "pipeline \(pipelineStatus.name)",
                tint: tint,
                systemImage: icon,
                hint: "Latest pipeline on this branch. Click to open it."
            ))
            #expect(status.pipelineURL == URL(string: "https://gitlab.example.com/top/live/-/pipelines/7"))
        }
    }

    @Test func pipelineHintMentionsTheUpdateTime() throws {
        let pipeline = PipelineInfo(status: .success, webURL: nil, updatedAt: Date(timeIntervalSinceNow: -300))

        let status = try mapStatus(request: nil, pipeline: pipeline)

        let hint = try #require(status.pipelineTag?.hint)
        #expect(hint.hasPrefix("Latest pipeline on this branch, "))
        #expect(hint.hasSuffix(". Click to open it."))
        #expect(status.pipelineURL == nil)
    }

    @Test func theOpenRequestAddsApprovalsAndOpenThreads() throws {
        let info = MergeRequestInfo(iid: 21, title: "ABC-5: Login", state: .opened, isDraft: false, webURL: URL(string: "https://gitlab.example.com/mr/21"), author: "sam", hasConflicts: false, detailedStatus: nil, targetBranch: "dev")
        let summary = MergeRequestSummaryFixture.request(iid: 21, source: "feature/login", state: .opened, approvedBy: ["kim"], threadCount: 2)
        let other = MergeRequestSummaryFixture.request(iid: 99, source: "feature/login", state: .opened, approvedBy: ["kim"])

        let status = try mapStatus(request: info, pipeline: nil, openRequest: summary)
        let mismatch = try mapStatus(request: info, pipeline: nil, openRequest: other)

        #expect(status.requestIID == 21)
        #expect(status.linkText == "!21 ABC-5: Login\nhttps://gitlab.example.com/mr/21")
        #expect(status.requestURL == URL(string: "https://gitlab.example.com/mr/21"))
        #expect(status.requestTags.map(\.text) == ["approved by kim", "2 open threads"])
        #expect(mismatch.requestTags.isEmpty)
    }

    private func mapStatus(request: MergeRequestInfo?, pipeline: PipelineInfo?, openRequest: MergeRequestSummary? = nil) throws -> MergeRequestLineModel.Status {
        let model = MergeRequestLineMapper.model(status: MergeRequestStatus(mergeRequest: request, pipeline: pipeline), error: nil, isLoading: false, openRequest: openRequest, username: "me")
        guard case .status(let status) = model.content else {
            throw MapperFailure.notStatus
        }
        return status
    }
}

private enum MapperFailure: Error {
    case notStatus
}
