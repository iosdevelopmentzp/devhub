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
    private let testFile = PullRequestFileDiff(
        oldPath: "AppTests/LoginTests.swift",
        path: "AppTests/LoginTests.swift",
        kind: .added,
        additions: 10,
        deletions: 0,
        diff: GitDiff(lines: ["@@ -0,0 +1 @@", "+x"], droppedLines: 0, isBinary: false),
        isTooLarge: false
    )

    @Test func loadingAndFailure() {
        #expect(PullRequestDetailsMapper.model(summary: summary, details: nil, diffs: nil, error: nil, review: review(expanded: [], focus: nil, busy: []), context: context()).content == .loading)
        #expect(PullRequestDetailsMapper.model(summary: summary, details: details, diffs: nil, error: nil, review: review(expanded: [], focus: nil, busy: []), context: context()).content == .loading)
        #expect(PullRequestDetailsMapper.model(summary: summary, details: details, diffs: files, error: "boom", review: review(expanded: [], focus: nil, busy: []), context: context()).content == .failure("boom"))
    }

    @Test func loadedDetails() throws {
        let loaded = try loaded(PullRequestDetailsMapper.model(summary: summary, details: details, diffs: files, error: nil, review: review(expanded: ["a.swift"], focus: nil, busy: []), context: context()))

        #expect(loaded.description.map { String($0.characters) } == "Adds login.")
        #expect(loaded.threadsTitle == "Open threads 1")
        #expect(loaded.canFixThreads == (summary.state == .opened))
        #expect(loaded.threads.map(\.id) == ["1"])
        #expect(loaded.threads.map(\.canShowInDiff) == [false])
        #expect(loaded.threads.map(\.isBusy) == [false])
        #expect(try self.loaded(PullRequestDetailsMapper.model(summary: summary, details: details, diffs: files, error: nil, review: review(expanded: [], focus: nil, busy: ["1"]), context: context())).threads[0].isBusy)
        #expect(loaded.threads[0].noteURL == URL(string: "https://gitlab.example.com/team/app/-/merge_requests/7#note_9"))
        #expect(loaded.pipelineTag?.text == "pipeline running")
        #expect(loaded.pipelineURL == URL(string: "https://gitlab.example.com/p/1"))
        #expect(loaded.filesTitle == "Files 2 · +5 −1")
        #expect(loaded.hiddenFilesTitle == nil)
        #expect(loaded.canExpandAllFiles)
        #expect(loaded.canCollapseAllFiles)
        #expect(loaded.hasThreadsInDiff == false)
        #expect(loaded.showsThreadsInDiff)
        #expect(loaded.files.map(\.isExpanded) == [true, false])
        #expect(loaded.diffLayout == .unified)
        #expect(loaded.files[0].diff != nil)
        #expect(loaded.files[1].diff == nil)
    }

    @Test func emptyDescriptionAndNoThreads() throws {
        let empty = PullRequestDetails(description: "  \n", threads: [])

        let loaded = try loaded(PullRequestDetailsMapper.model(summary: summary, details: empty, diffs: [], error: nil, review: review(expanded: [], focus: nil, busy: []), context: context()))

        #expect(loaded.description == nil)
        #expect(loaded.threadsTitle == "No open threads")
        #expect(loaded.canFixThreads == false)
        #expect(loaded.filesTitle == "Files 0 · +0 −0")
    }

    @Test func viewedFilesCountInTheTitleAndInExpandAll() throws {
        let allOpen = try loaded(PullRequestDetailsMapper.model(summary: summary, details: details, diffs: files, error: nil, review: review(expanded: ["a.swift", "b.png"]), context: context()))
        let viewed = try loaded(PullRequestDetailsMapper.model(summary: summary, details: details, diffs: files, error: nil, review: review(expanded: ["a.swift"], viewed: ["b.png"]), context: context()))
        let closed = try loaded(PullRequestDetailsMapper.model(summary: summary, details: details, diffs: files, error: nil, review: review(expanded: []), context: context()))

        #expect(allOpen.canExpandAllFiles == false)
        #expect(viewed.filesTitle == "Files 2 · +5 −1 · 1 viewed")
        #expect(viewed.canExpandAllFiles == false)
        #expect(viewed.files.map(\.isViewed) == [false, true])
        #expect(closed.canCollapseAllFiles == false)
        #expect(closed.canExpandAllFiles)
    }

    @Test func filesThatMatchTheHiddenPatternsStayOutOfTheListUntilShown() throws {
        let patterns = ["*Tests/*", "*.png"]
        let hidden = try loaded(PullRequestDetailsMapper.model(summary: summary, details: details, diffs: files + [testFile], error: nil, review: review(expanded: ["AppTests/LoginTests.swift"]), context: context(hiddenFiles: patterns)))
        var shownState = review(expanded: ["AppTests/LoginTests.swift"])
        shownState.showsHiddenFiles = true
        let shown = try loaded(PullRequestDetailsMapper.model(summary: summary, details: details, diffs: files + [testFile], error: nil, review: shownState, context: context(hiddenFiles: patterns)))

        #expect(hidden.files.map(\.id) == ["a.swift"])
        #expect(hidden.filesTitle == "Files 1 · +2 −1")
        #expect(hidden.hiddenFilesTitle == "Show 2 hidden")
        #expect(hidden.hiddenFilesHint?.contains("2 files") == true)
        #expect(hidden.showsHiddenFiles == false)
        #expect(hidden.canExpandAllFiles)
        #expect(hidden.canCollapseAllFiles == false)
        #expect(shown.files.map(\.id) == ["a.swift", "b.png", "AppTests/LoginTests.swift"])
        #expect(shown.filesTitle == "Files 3 · +15 −1")
        #expect(shown.hiddenFilesTitle == "Hide 2")
        #expect(shown.showsHiddenFiles)
        #expect(shown.canCollapseAllFiles)
    }

    @Test func filesYouHidStayOutOfTheListAndCanBeShownAgain() throws {
        var hiddenState = review(expanded: [])
        hiddenState.chosenHiddenFiles = ["b.png"]
        var shownState = hiddenState
        shownState.showsHiddenFiles = true

        let hidden = try loaded(PullRequestDetailsMapper.model(summary: summary, details: details, diffs: files, error: nil, review: hiddenState, context: context()))
        let shown = try loaded(PullRequestDetailsMapper.model(summary: summary, details: details, diffs: files, error: nil, review: shownState, context: context()))

        #expect(hidden.files.map(\.id) == ["a.swift"])
        #expect(hidden.hiddenFilesTitle == "Show 1 hidden")
        #expect(hidden.hiddenFilesHint == "1 file is hidden: you hid it, it is in a hidden group, or it matches git.pullRequests.hiddenFiles. Click to show them.")
        #expect(hidden.files[0].canHide)
        #expect(hidden.files[0].hiddenTag == nil)
        #expect(shown.files.map(\.id) == ["a.swift", "b.png"])
        #expect(shown.files[1].canHide == false)
        #expect(shown.files[1].canUnhide)
        #expect(shown.files[1].hiddenTag?.text == "hidden")
    }

    @Test func nothingIsHiddenWithoutAChoiceButTestsAndLockFilesAreSuggested() throws {
        let lock = PullRequestFileDiff(oldPath: "Podfile.lock", path: "Podfile.lock", kind: .modified, additions: 1, deletions: 1, diff: GitDiff(lines: [], droppedLines: 0, isBinary: false), isTooLarge: false)

        let model = try loaded(PullRequestDetailsMapper.model(summary: summary, details: details, diffs: files + [testFile, lock], error: nil, review: review(expanded: []), context: context()))
        let suggestion = try #require(model.hideSuggestion)

        #expect(model.files.map(\.id) == ["a.swift", "b.png", "AppTests/LoginTests.swift", "Podfile.lock"])
        #expect(model.hiddenFilesTitle == nil)
        #expect(suggestion.paths == ["AppTests/LoginTests.swift", "Podfile.lock"])
        #expect(suggestion.text == "2 files look like tests, project files or lock files")
        #expect(suggestion.actionTitle == "Hide Them")
        #expect(suggestion.hint.hasPrefix("Hide LoginTests.swift, Podfile.lock in the requests of this project."))
    }

    @Test func aSuggestionNamesThreeFilesThenCountsTheRest() throws {
        let suggestion = try #require(PullRequestDetailsMapper.hideSuggestion(["A/aTests.swift", "B/bTests.swift", "c.lock", "d.lock", "e.resolved"]))
        let single = try #require(PullRequestDetailsMapper.hideSuggestion(["c.lock"]))

        #expect(suggestion.hint.hasPrefix("Hide aTests.swift, bTests.swift, c.lock and 2 more in the requests"))
        #expect(single.text == "1 file looks like tests, project files or lock files")
        #expect(single.actionTitle == "Hide It")
        #expect(PullRequestDetailsMapper.hideSuggestion([]) == nil)
    }

    @Test func aThreadOnAHiddenFileCannotBeShownInTheDiff() throws {
        let thread = ReviewThread(id: "t", noteID: nil, author: "sam", body: "Test this", filePath: "AppTests/LoginTests.swift", line: 1, isOnOldLine: false, replies: [])
        let withThread = PullRequestDetails(description: "", threads: [thread])

        let hidden = try loaded(PullRequestDetailsMapper.model(summary: summary, details: withThread, diffs: [testFile], error: nil, review: review(expanded: []), context: context(hiddenFiles: ["*Tests/*"])))
        let visible = try loaded(PullRequestDetailsMapper.model(summary: summary, details: withThread, diffs: [testFile], error: nil, review: review(expanded: []), context: context(hiddenFiles: [])))

        #expect(hidden.threads.map(\.canShowInDiff) == [false])
        #expect(hidden.hasThreadsInDiff == false)
        #expect(visible.threads.map(\.canShowInDiff) == [true])
        #expect(visible.hasThreadsInDiff)
    }

    @Test func reviewLinesAndJobGroupsComeFromTheSummaryAndTheJobs() throws {
        let reviewed = PullRequestSummaryFixture.request(iid: 7, source: "x", state: .opened, approvedBy: ["kim"], reviewers: ["kim", "lee"])
        let withJobs = PullRequestDetails(description: "", threads: [], jobs: [PipelineJob(name: "unit", stage: "test", webURL: nil, id: "2", status: .success)])

        let loaded = try loaded(PullRequestDetailsMapper.model(summary: reviewed, details: withJobs, diffs: [], error: nil, review: review(expanded: []), context: context()))

        #expect(loaded.reviewLines.map(\.title) == ["Approved by", "Waiting for"])
        #expect(loaded.reviewLines[1].tags.map(\.text) == ["lee"])
        #expect(loaded.jobGroups.map(\.title) == ["test"])
        #expect(loaded.jobsTitle == "Pipeline 1")
    }

    private func context(hiddenFiles: [String] = [], fileGroups: [PullRequestFileGroup] = []) -> PullRequestRowContext {
        PullRequestRowContext(username: "me", scope: .all, seenAt: nil, now: .now, isMainCheckoutClean: true, ticket: .standard, words: .gitLab, staleDays: 14, hiddenFiles: hiddenFiles, fileGroups: fileGroups, watchedIDs: [])
    }

    @Test func aGroupHiddenByDefaultKeepsItsFilesOutUntilItsChipIsToggled() throws {
        let groups = [
            PullRequestFileGroup(name: "Tests", patterns: ["*Tests/*"], isHiddenByDefault: true),
            PullRequestFileGroup(name: "Images", patterns: ["*.png"], isHiddenByDefault: false),
        ]
        var toggledState = review(expanded: [])
        toggledState.toggledGroups = ["Tests", "Images"]

        let hidden = try loaded(PullRequestDetailsMapper.model(summary: summary, details: details, diffs: files + [testFile], error: nil, review: review(expanded: []), context: context(fileGroups: groups)))
        let toggled = try loaded(PullRequestDetailsMapper.model(summary: summary, details: details, diffs: files + [testFile], error: nil, review: toggledState, context: context(fileGroups: groups)))

        #expect(hidden.fileGroups.map(\.title) == ["Tests 1", "Images 1"])
        #expect(hidden.fileGroups.map(\.isHidden) == [true, false])
        #expect(hidden.files.map(\.id) == ["a.swift", "b.png"])
        #expect(hidden.hiddenFilesTitle == "Show 1 hidden")
        #expect(hidden.hiddenFilesHint == "1 file is hidden: you hid it, it is in a hidden group, or it matches git.pullRequests.hiddenFiles. Click to show them.")
        #expect(hidden.hideSuggestion == nil)
        #expect(toggled.fileGroups.map(\.isHidden) == [false, true])
        #expect(toggled.files.map(\.id) == ["a.swift", "AppTests/LoginTests.swift"])
        #expect(toggled.hiddenFilesTitle == "Show 1 hidden")
    }

    @Test func aFileOfAHiddenGroupShowsItsGroupInTheHiddenTag() throws {
        let groups = [PullRequestFileGroup(name: "Tests", patterns: ["*Tests/*"], isHiddenByDefault: true)]
        var shownState = review(expanded: [])
        shownState.showsHiddenFiles = true

        let shown = try loaded(PullRequestDetailsMapper.model(summary: summary, details: details, diffs: files + [testFile], error: nil, review: shownState, context: context(fileGroups: groups)))

        #expect(shown.files.map(\.id) == ["a.swift", "b.png", "AppTests/LoginTests.swift"])
        #expect(shown.files[2].hiddenTag?.hint?.contains("group Tests") == true)
        #expect(shown.files[2].canHide == false)
        #expect(shown.hiddenFilesTitle == "Hide 1")
    }

    @Test func theHideSuggestionLeavesOutFilesOfAShownGroup() throws {
        let groups = [PullRequestFileGroup(name: "Tests", patterns: ["*Tests/*"], isHiddenByDefault: false)]

        let model = try loaded(PullRequestDetailsMapper.model(summary: summary, details: details, diffs: files + [testFile], error: nil, review: review(expanded: []), context: context(fileGroups: groups)))

        #expect(model.files.map(\.id) == ["a.swift", "b.png", "AppTests/LoginTests.swift"])
        #expect(model.hideSuggestion == nil)
        #expect(model.fileGroups.map(\.title) == ["Tests 1"])
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

        let loaded = try loaded(PullRequestDetailsMapper.model(summary: running, details: withJobs, diffs: [], error: nil, review: review(expanded: [], focus: nil, busy: []), context: context()))

        #expect(loaded.failedJobs == [
            PullRequestDetailsModel.JobLink(title: "build-ios (test)", url: URL(string: "https://gitlab.example.com/j/1")),
            PullRequestDetailsModel.JobLink(title: "lint", url: nil),
        ])
        #expect(loaded.pipelineDurationText?.hasPrefix("took ") == true)
        #expect(loaded.canCancelPipeline)
    }

    @Test func aPipelineWithoutIDOrFinishedCannotBeCancelled() throws {
        let finished = PullRequestSummaryFixture.request(iid: 7, source: "x", state: .opened, pipeline: PipelineInfo(status: .success, webURL: nil, updatedAt: nil, id: 90))

        #expect(try loaded(PullRequestDetailsMapper.model(summary: summary, details: details, diffs: files, error: nil, review: review(expanded: [], focus: nil, busy: []), context: context())).canCancelPipeline == false)
        #expect(try loaded(PullRequestDetailsMapper.model(summary: finished, details: details, diffs: files, error: nil, review: review(expanded: [], focus: nil, busy: []), context: context())).canCancelPipeline == false)
        #expect(try loaded(PullRequestDetailsMapper.model(summary: finished, details: details, diffs: files, error: nil, review: review(expanded: [], focus: nil, busy: []), context: context())).pipelineDurationText == nil)
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

    @Test func theCircleCINoticeFollowsTheToolState() {
        var review = PullRequestReviewState.initial
        #expect(PullRequestDetailsMapper.ciNotice(review: review) == nil)

        review.hasCIProvider = true
        #expect(PullRequestDetailsMapper.ciNotice(review: review) == nil)

        review.ciToolState = .missing
        #expect(PullRequestDetailsMapper.ciNotice(review: review)?.command == "brew install circleci && circleci auth login")

        review.ciToolState = CIToolState(isInstalled: true, version: "0.1.3", isLoggedIn: false)
        #expect(PullRequestDetailsMapper.ciNotice(review: review)?.text.contains("0.1.3") == true)
        #expect(PullRequestDetailsMapper.ciNotice(review: review)?.command == "brew upgrade circleci")

        review.ciToolState = CIToolState(isInstalled: true, version: "1.13.0", isLoggedIn: false)
        #expect(PullRequestDetailsMapper.ciNotice(review: review)?.command == "circleci auth login")

        review.ciToolState = CIToolState(isInstalled: true, version: "1.13.0", isLoggedIn: true)
        #expect(PullRequestDetailsMapper.ciNotice(review: review) == nil)
    }

    @Test func theAutoRerunControlFollowsThePlanAndTheTool() throws {
        var review = PullRequestReviewState.initial
        #expect(PullRequestDetailsMapper.autoRerun(review: review) == nil)

        review.hasCIProvider = true
        review.ciToolState = .missing
        #expect(PullRequestDetailsMapper.autoRerun(review: review) == nil)

        review.ciToolState = CIToolState(isInstalled: true, version: "1.13.0", isLoggedIn: true)
        let off = try #require(PullRequestDetailsMapper.autoRerun(review: review))
        #expect(off.isOn == false)
        #expect(off.title == "Auto re-run")
        #expect(off.choices.map(\.count) == CIAutoRerunPolicy.attemptChoices)
        #expect(off.choices.first?.title == "Up to 3 times")
        #expect(off.onlyFlaky)
        #expect(off.onlyFlakyTitle == "Only flaky failures")
        #expect(off.onlyFlakyHint == PullRequestDetailsMapper.onlyFlakyHint)
        #expect(off.hint.hasPrefix("Run the failed CircleCI jobs again when every failed test is flaky"))

        review.autoRerunOnlyFlaky = false
        let any = try #require(PullRequestDetailsMapper.autoRerun(review: review))
        #expect(any.onlyFlaky == false)
        #expect(any.hint.hasPrefix("Run the failed CircleCI jobs again each time a workflow fails"))

        review.hasCIProvider = false
        review.autoRerunPlan = CIAutoRerunPlan(iid: 7, maxAttempts: 10, attempts: 9, handledWorkflowIDs: [], lastRerunAt: nil)
        let on = try #require(PullRequestDetailsMapper.autoRerun(review: review))
        #expect(on.isOn)
        #expect(on.title == "Auto re-run 9 of 10")
        #expect(on.hint == "DevHub runs the failed CircleCI jobs again when every failed test is flaky. 1 re-run left. Click to stop.")
        #expect(on.onlyFlaky)
        #expect(on.choices.isEmpty)
    }

    @Test func thePreviousCircleCIRunsGetATitle() throws {
        var withHistory = review(expanded: [])
        withHistory.ciHistory = [CIWorkflowRecord(workflow: CIWorkflow(id: "w1", name: "build", status: .failed, runID: nil, jobs: []), failedTests: [:], recordedAt: .now)]
        withHistory.showsCIHistory = true

        let shown = try loaded(PullRequestDetailsMapper.model(summary: summary, details: details, diffs: files, error: nil, review: withHistory, context: context()))
        let empty = try loaded(PullRequestDetailsMapper.model(summary: summary, details: details, diffs: files, error: nil, review: review(expanded: []), context: context()))

        #expect(shown.ciHistoryTitle == "Previous CircleCI runs 1")
        #expect(shown.showsCIHistory)
        #expect(shown.ciHistory.map(\.id) == ["w1"])
        #expect(empty.ciHistoryTitle == nil)
        #expect(empty.ciHistory.isEmpty)
    }

    @Test func withoutAReviewThereIsNoNotice() throws {
        let loaded = try loaded(PullRequestDetailsMapper.model(summary: summary, details: details, diffs: files, error: nil, review: review(expanded: []), context: context()))

        #expect(loaded.reviewNotice == nil)
        #expect(loaded.files.allSatisfy { $0.reviewTag == nil })
    }

    @Test func changedFilesAreCountedAndTagged() throws {
        var state = review(expanded: [])
        state.reviewedAt = Date(timeIntervalSince1970: 1_800_000_000)
        state.changedSinceReview = ["b.png"]

        let loaded = try loaded(PullRequestDetailsMapper.model(summary: summary, details: details, diffs: files, error: nil, review: state, context: context()))

        #expect(loaded.reviewNotice?.text.hasPrefix("1 file changed since your review") == true)
        #expect(loaded.reviewNotice?.tint == .orange)
        #expect(loaded.reviewNotice?.toggleTitle == "Show Only These")
        #expect(loaded.reviewNotice?.hint.contains("GitLab") == true)
        #expect(loaded.files.map(\.reviewTag) == [nil, PullRequestDetailsMapper.changedSinceReviewTag])
    }

    @Test func showOnlyChangedListsTheChangedFiles() throws {
        var state = review(expanded: [])
        state.reviewedAt = Date(timeIntervalSince1970: 1_800_000_000)
        state.changedSinceReview = ["b.png"]
        state.showsOnlyChangedSinceReview = true

        let loaded = try loaded(PullRequestDetailsMapper.model(summary: summary, details: details, diffs: files, error: nil, review: state, context: context()))

        #expect(loaded.files.map(\.id) == ["b.png"])
        #expect(loaded.reviewNotice?.toggleTitle == "Show All Files")
        #expect(loaded.filesTitle.hasPrefix("Files 2"))
    }

    @Test func noChangeSinceTheReviewIsGreen() throws {
        var state = review(expanded: [])
        state.reviewedAt = Date(timeIntervalSince1970: 1_800_000_000)
        state.showsOnlyChangedSinceReview = true

        let loaded = try loaded(PullRequestDetailsMapper.model(summary: summary, details: details, diffs: files, error: nil, review: state, context: context()))

        #expect(loaded.reviewNotice?.text.hasPrefix("No file changed since your review") == true)
        #expect(loaded.reviewNotice?.tint == .green)
        #expect(loaded.reviewNotice?.toggleTitle == nil)
        #expect(loaded.files.count == 2)
    }
}
