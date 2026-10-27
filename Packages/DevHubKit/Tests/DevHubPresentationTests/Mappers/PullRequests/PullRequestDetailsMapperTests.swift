import DevHubDomain
import DevHubUI
import Foundation
import Testing
import DevHubTestSupport
@testable import DevHubPresentation

@Suite struct PullRequestDetailsMapperTests {
    private let summary = PullRequestSummaryFixture.request(iid: 7, source: "x", state: .opened, pipeline: PipelineInfo(status: .running, webURL: URL(string: "https://gitlab.example.com/p/1"), updatedAt: nil))
    private let details = PullRequestDetails(
        description: "Adds **login**.",
        threads: [ReviewThread(id: "1", noteID: 9, author: "sam", body: "Move", filePath: "App/Login.swift", line: 12, isOnOldLine: false, replies: [PullRequestNote(author: "me", body: "a"), PullRequestNote(author: "sam", body: "b")])]
    )
    private let files = [
        PullRequestFileDiff(
            oldPath: "a.swift",
            path: "a.swift",
            kind: .modified,
            additions: 2,
            deletions: 1,
            diff: GitDiff(lines: ["@@ -1 +1 @@", "+x"], droppedLines: 0, isBinary: false),
            isTooLarge: false
        ),
        PullRequestFileDiff(
            oldPath: "b.png",
            path: "b.png",
            kind: .added,
            additions: 3,
            deletions: 0,
            diff: GitDiff(lines: [], droppedLines: 0, isBinary: false),
            isTooLarge: true
        ),
    ]

    @Test func loadingAndFailure() {
        #expect(PullRequestDetailsMapper.model(summary: summary, details: nil, diffs: nil, error: nil, review: review(expanded: [], focus: nil, busy: []), words: .gitLab).content == .loading)
        #expect(PullRequestDetailsMapper.model(summary: summary, details: details, diffs: nil, error: nil, review: review(expanded: [], focus: nil, busy: []), words: .gitLab).content == .loading)
        #expect(PullRequestDetailsMapper.model(summary: summary, details: details, diffs: files, error: "boom", review: review(expanded: [], focus: nil, busy: []), words: .gitLab).content == .failure("boom"))
    }

    @Test func loadedDetails() throws {
        let loaded = try loaded(PullRequestDetailsMapper.model(summary: summary, details: details, diffs: files, error: nil, review: review(expanded: ["a.swift"], focus: nil, busy: []), words: .gitLab))

        #expect(loaded.description.map { String($0.characters) } == "Adds login.")
        #expect(loaded.threadsTitle == "Open threads 1")
        #expect(loaded.canFixThreads == (summary.state == .opened))
        #expect(loaded.threads.map(\.id) == ["1"])
        #expect(loaded.threads.map(\.canShowInDiff) == [false])
        #expect(loaded.threads.map(\.isBusy) == [false])
        #expect(try self.loaded(PullRequestDetailsMapper.model(summary: summary, details: details, diffs: files, error: nil, review: review(expanded: [], focus: nil, busy: ["1"]), words: .gitLab)).threads[0].isBusy)
        #expect(loaded.threads[0].noteURL == URL(string: "https://gitlab.example.com/team/app/-/merge_requests/7#note_9"))
        #expect(loaded.pipelineTag?.text == "pipeline running")
        #expect(loaded.pipelineURL == URL(string: "https://gitlab.example.com/p/1"))
        #expect(loaded.filesTitle == "Files 2 · +5 −1")
        #expect(loaded.canExpandAllFiles)
        #expect(loaded.canCollapseAllFiles)
        #expect(loaded.hasThreadsInDiff == false)
        #expect(loaded.showsThreadsInDiff)
        #expect(loaded.files.map(\.isExpanded) == [true, false])
        #expect(loaded.files[0].diff != nil)
        #expect(loaded.files[1].diff == nil)
    }

    @Test func emptyDescriptionAndNoThreads() throws {
        let empty = PullRequestDetails(description: "  \n", threads: [])

        let loaded = try loaded(PullRequestDetailsMapper.model(summary: summary, details: empty, diffs: [], error: nil, review: review(expanded: [], focus: nil, busy: []), words: .gitLab))

        #expect(loaded.description == nil)
        #expect(loaded.threadsTitle == "No open threads")
        #expect(loaded.canFixThreads == false)
        #expect(loaded.filesTitle == "Files 0 · +0 −0")
    }

    @Test func viewedFilesCountInTheTitleAndInExpandAll() throws {
        let allOpen = try loaded(PullRequestDetailsMapper.model(summary: summary, details: details, diffs: files, error: nil, review: review(expanded: ["a.swift", "b.png"]), words: .gitLab))
        let viewed = try loaded(PullRequestDetailsMapper.model(summary: summary, details: details, diffs: files, error: nil, review: review(expanded: ["a.swift"], viewed: ["b.png"]), words: .gitLab))
        let closed = try loaded(PullRequestDetailsMapper.model(summary: summary, details: details, diffs: files, error: nil, review: review(expanded: []), words: .gitLab))

        #expect(allOpen.canExpandAllFiles == false)
        #expect(viewed.filesTitle == "Files 2 · +5 −1 · 1 viewed")
        #expect(viewed.canExpandAllFiles == false)
        #expect(viewed.files.map(\.isViewed) == [false, true])
        #expect(closed.canCollapseAllFiles == false)
        #expect(closed.canExpandAllFiles)
    }

    private func review(
        expanded: Set<String>,
        viewed: Set<String> = [],
        focus: DiffFocus? = nil,
        busy: Set<String> = []
    ) -> PullRequestReviewState {
        PullRequestReviewState(expandedFiles: expanded, viewedFiles: viewed, focus: focus, busyThreads: busy, showsThreadsInDiff: true, openDiffThreads: [])
    }

    private func loaded(_ model: PullRequestDetailsModel) throws -> PullRequestDetailsModel.Loaded {
        guard case .loaded(let loaded) = model.content else {
            throw TestError.scripted("not loaded")
        }
        return loaded
    }

    @Test func failedJobsDurationAndCancel() throws {
        let running = PullRequestSummaryFixture.request(iid: 7, source: "x", state: .opened, pipeline: PipelineInfo(status: .running, webURL: nil, updatedAt: nil, id: 90))
        let withJobs = PullRequestDetails(
            description: "",
            threads: [],
            failedJobs: [
                PipelineJob(name: "build-ios", stage: "test", webURL: URL(string: "https://gitlab.example.com/j/1")),
                PipelineJob(name: "lint", stage: nil, webURL: nil),
            ],
            pipelineDuration: 540
        )

        let loaded = try loaded(PullRequestDetailsMapper.model(summary: running, details: withJobs, diffs: [], error: nil, review: review(expanded: [], focus: nil, busy: []), words: .gitLab))

        #expect(loaded.failedJobs == [
            PullRequestDetailsModel.JobLink(title: "build-ios (test)", url: URL(string: "https://gitlab.example.com/j/1")),
            PullRequestDetailsModel.JobLink(title: "lint", url: nil),
        ])
        #expect(loaded.pipelineDurationText?.hasPrefix("took ") == true)
        #expect(loaded.canCancelPipeline)
    }

    @Test func aPipelineWithoutIDOrFinishedCannotBeCancelled() throws {
        let finished = PullRequestSummaryFixture.request(iid: 7, source: "x", state: .opened, pipeline: PipelineInfo(status: .success, webURL: nil, updatedAt: nil, id: 90))

        #expect(try loaded(PullRequestDetailsMapper.model(summary: summary, details: details, diffs: files, error: nil, review: review(expanded: [], focus: nil, busy: []), words: .gitLab)).canCancelPipeline == false)
        #expect(try loaded(PullRequestDetailsMapper.model(summary: finished, details: details, diffs: files, error: nil, review: review(expanded: [], focus: nil, busy: []), words: .gitLab)).canCancelPipeline == false)
        #expect(try loaded(PullRequestDetailsMapper.model(summary: finished, details: details, diffs: files, error: nil, review: review(expanded: [], focus: nil, busy: []), words: .gitLab)).pipelineDurationText == nil)
    }

    @Test func theCommentBoxNeedsTextAndOffersRequestChangesOnlyWhenAllowed() {
        var state = review(expanded: [])
        state.commentDraft = "  "
        let empty = PullRequestDetailsMapper.commentBox(summary: summary, review: state, words: .gitHub)
        #expect(empty.canSend == false)
        #expect(empty.canRequestChanges == false)
        #expect(empty.placeholder == "Comment on #7…")

        state.commentDraft = "Fix"
        let allowed = PullRequestSummaryFixture.request(
            iid: 7,
            source: "x",
            state: .opened,
            permissions: PullRequestPermissions(canMerge: false, canApprove: true, canRevokeApproval: false, canSetAutoMerge: false, canRequestChanges: true)
        )
        let ready = PullRequestDetailsMapper.commentBox(summary: allowed, review: state, words: .gitHub)
        #expect(ready.canSend)
        #expect(ready.canRequestChanges)

        state.isCommentBusy = true
        #expect(PullRequestDetailsMapper.commentBox(summary: allowed, review: state, words: .gitHub).canSend == false)
    }
}
