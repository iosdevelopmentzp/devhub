import Foundation
import Testing
import DevHubDomain
import DevHubTestSupport
@testable import DevHubPresentation

@Suite struct PullRequestDetailStoreTests {
    private let harness = StoreHarness()
    private let remote = CodeHost.gitLabSample
    private let details = PullRequestDetails(
        description: "Adds login",
        threads: [
            ReviewThread(id: "t1", noteID: nil, author: "sam", body: "Move", filePath: "a.swift", line: 4, isOnOldLine: true, replies: []),
            ReviewThread(id: "t2", noteID: nil, author: "sam", body: "General", filePath: nil, line: nil, isOnOldLine: false, replies: []),
        ]
    )
    private let files = [
        PullRequestFileDiff(
            oldPath: "a.swift",
            path: "a.swift",
            kind: .modified,
            additions: 1,
            deletions: 0,
            diff: GitDiff(lines: ["+x"], droppedLines: 0, isBinary: false),
            isTooLarge: false
        ),
    ]

    private var store: PullRequestDetailStore {
        harness.pullRequestDetails
    }

    private func script() {
        harness.spies.git.webURLResult = remote.webURL
        harness.spies.codeHost.detailsResult = .success(details)
        harness.spies.codeHost.diffsResult = .success(files)
    }

    @Test func loadReadsDetailsAndDiffsOnce() async {
        script()

        await store.load(7)
        await store.load(7)

        #expect(store.details[7] == details)
        #expect(store.diffs[7] == files)
        #expect(store.errors[7] == nil)
        #expect(store.isLoaded(7))
        #expect(Set(harness.spies.codeHost.calls) == [.details(iid: 7, repository: remote), .diffs(iid: 7, repository: remote)])
        #expect(harness.spies.codeHost.calls.count == 2)
    }

    @Test func aFailureIsKeptPerRequestAndReloadRetries() async {
        script()
        harness.spies.codeHost.diffsResult = .failure(PullRequestError.command("boom"))

        await store.load(7)

        #expect(store.errors[7] == "boom")
        #expect(store.isLoaded(7) == false)

        harness.spies.codeHost.diffsResult = .success(files)
        await store.reload(7)

        #expect(store.errors[7] == nil)
        #expect(store.isLoaded(7))
    }

    @Test func toggleFileKeepsSeveralFilesOpenPerRequest() {
        store.toggleFile("a.swift", of: 7)
        store.toggleFile("b.swift", of: 7)
        store.toggleFile("x.swift", of: 8)

        #expect(store.expandedFiles(of: 7) == ["a.swift", "b.swift"])
        #expect(store.expandedFiles(of: 8) == ["x.swift"])

        store.toggleFile("a.swift", of: 7)
        #expect(store.expandedFiles(of: 7) == ["b.swift"])
    }

    @Test func expandAllOpensTheFilesNotViewedAndCollapseAllClosesThem() async {
        script()
        harness.spies.codeHost.diffsResult = .success(files + [PullRequestFileDiff(oldPath: "b.swift", path: "b.swift", kind: .added, additions: 1, deletions: 0, diff: GitDiff(lines: ["+y"], droppedLines: 0, isBinary: false), isTooLarge: false)])
        await store.load(7)
        store.toggleViewed("b.swift", of: 7)

        store.expandAllFiles(["a.swift", "b.swift"], of: 7)
        #expect(store.expandedFiles(of: 7) == ["a.swift"])

        store.collapseAllFiles(of: 7)
        #expect(store.expandedFiles(of: 7).isEmpty)
    }

    @Test func expandAllOpensOnlyTheListedFilesAndKeepsTheOpenOnes() {
        store.toggleFile("c.swift", of: 7)

        store.expandAllFiles(["a.swift"], of: 7)

        #expect(store.expandedFiles(of: 7) == ["a.swift", "c.swift"])
    }

    @Test func hiddenFilesShowPerRequestUntilToggledBack() {
        #expect(store.review(of: 7).showsHiddenFiles == false)

        store.toggleHiddenFiles(of: 7)
        #expect(store.review(of: 7).showsHiddenFiles)
        #expect(store.review(of: 8).showsHiddenFiles == false)

        store.toggleHiddenFiles(of: 7)
        #expect(store.review(of: 7).showsHiddenFiles == false)
    }

    @Test func markingAFileViewedFoldsItAndUnmarkingKeepsItFolded() {
        store.toggleFile("a.swift", of: 7)

        store.toggleViewed("a.swift", of: 7)
        #expect(store.review(of: 7).viewedFiles == ["a.swift"])
        #expect(store.expandedFiles(of: 7).isEmpty)

        store.toggleViewed("a.swift", of: 7)
        #expect(store.review(of: 7).viewedFiles.isEmpty)
        #expect(store.expandedFiles(of: 7).isEmpty)
    }

    @Test func showInDiffOpensTheFileAndFocusesTheLine() async {
        script()
        await store.load(7)

        store.showInDiff(threadID: "t1", of: 7)

        #expect(store.expandedFiles(of: 7) == ["a.swift"])
        #expect(store.focus(of: 7) == DiffFocus(requestID: 7, path: "a.swift", line: 4, isOld: true))
        #expect(store.focus(of: 8) == nil)

        store.toggleFile("x.swift", of: 8)
        #expect(store.focus(of: 7) != nil)

        store.toggleFile("b.swift", of: 7)
        #expect(store.focus == nil)

        store.showInDiff(threadID: "t2", of: 7)
        #expect(store.expandedFiles(of: 7) == ["a.swift", "b.swift"])
        #expect(store.focus == nil)
    }

    @Test func showInDiffOpensTheThreadUnderItsLine() async {
        script()
        await store.load(7)

        store.showInDiff(threadID: "t1", of: 7)

        #expect(store.review(of: 7).openDiffThreads == ["t1"])
    }

    @Test func threadsInTheDiffFoldOneByOneOrAllTogether() async {
        script()
        await store.load(7)

        store.toggleDiffThread("t1")
        #expect(store.openDiffThreads == ["t1"])
        store.toggleDiffThread("t1")
        #expect(store.openDiffThreads.isEmpty)

        store.toggleThreadsInDiff()
        #expect(store.review(of: 7).showsThreadsInDiff == false)

        store.openAllDiffThreads(of: 7)
        #expect(store.showsThreadsInDiff)
        #expect(store.openDiffThreads == ["t1", "t2"])

        store.foldAllDiffThreads(of: 7)
        #expect(store.openDiffThreads.isEmpty)
    }

    @Test func aCancelledLoadLeavesNoError() async {
        script()
        harness.spies.codeHost.detailsResult = .failure(CancellationError())

        await store.load(7)

        #expect(store.errors[7] == nil)
        #expect(store.isLoaded(7) == false)
    }

    @Test func resolveAndReplyCallGitLabAndReloadTheDetails() async throws {
        script()
        await store.load(7)

        store.resolveThread("t1", of: 7)
        #expect(store.busyThreads == ["t1"])
        try await waitUntil { store.busyThreads.isEmpty && harness.spies.codeHost.calls.count == 5 }
        #expect(harness.spies.codeHost.calls.contains(.resolveThread(id: "t1", repository: remote)))
        #expect(harness.lastActivity?.title == "Resolved a thread of !7")

        store.reply("  ", to: "t1", of: 7)
        #expect(store.busyThreads.isEmpty)

        store.reply(" Looks good ", to: "t2", of: 7)
        try await waitUntil { store.busyThreads.isEmpty && harness.spies.codeHost.calls.count == 8 }
        #expect(harness.spies.codeHost.calls.contains(.reply(threadID: "t2", body: "Looks good", iid: 7, repository: remote)))
    }

    @Test func aFailedThreadActionIsLogged() async throws {
        script()
        await store.load(7)
        harness.spies.codeHost.actionError = PullRequestError.command("boom")

        store.resolveThread("t1", of: 7)
        try await waitUntil { store.busyThreads.isEmpty }

        #expect(harness.lastActivity?.outcome == .failure)
        #expect(harness.spies.codeHost.calls.count == 3)
    }

    @Test func projectChangedClearsTheCache() async {
        script()
        await store.load(7)
        store.toggleFile("a.swift", of: 7)
        store.toggleViewed("b.swift", of: 7)

        harness.events.post(.projectChanged)

        #expect(store.details.isEmpty)
        #expect(store.diffs.isEmpty)
        #expect(store.expandedFiles(of: 7).isEmpty)
        #expect(store.review(of: 7) == .initial)
    }

    // MARK: Review prompt

    @Test func reviewPromptHoldsTheOpenThreadsAndReturnsTheFile() async {
        script()
        harness.spies.reviewPrompts.saveResult = .success("/tmp/prompts/mr-7.md")
        let summary = PullRequestSummaryFixture.request(iid: 7, source: "feature/login", state: .opened)

        let path = await store.writeReviewPrompt(for: summary)

        #expect(path == "/tmp/prompts/mr-7.md")
        #expect(harness.spies.reviewPrompts.calls == [.save(ReviewPromptBuilder.prompt(for: summary, threads: details.threads), iid: 7)])
    }

    @Test func reviewPromptWithoutOpenThreadsWritesNothing() async {
        script()
        harness.spies.codeHost.detailsResult = .success(PullRequestDetails(description: "", threads: []))

        let path = await store.writeReviewPrompt(for: PullRequestSummaryFixture.request(iid: 7, source: "x", state: .opened))

        #expect(path == nil)
        #expect(harness.spies.reviewPrompts.calls.isEmpty)
        #expect(harness.lastActivity?.title == "!7 has no open threads")
    }

    @Test func reviewPromptFailuresAreLogged() async {
        script()
        harness.spies.reviewPrompts.saveResult = .failure(TestError.scripted("disk full"))

        let path = await store.writeReviewPrompt(for: PullRequestSummaryFixture.request(iid: 7, source: "x", state: .opened))

        #expect(path == nil)
        #expect(harness.lastActivity?.title == "Cannot write the review prompt of !7")
        #expect(harness.lastActivity?.outcome == .failure)
    }

    @Test func reviewPromptReportsUnreadableDetails() async {
        script()
        harness.spies.codeHost.detailsResult = .failure(TestError.scripted("403"))

        let path = await store.writeReviewPrompt(for: PullRequestSummaryFixture.request(iid: 7, source: "x", state: .opened))

        #expect(path == nil)
        #expect(harness.lastActivity?.title == "Cannot read the threads of !7")
    }

    @Test func aCommentSendsTheTrimmedDraftAndClearsItAfterwards() async throws {
        script()
        await store.load(7)
        store.setCommentDraft("  Looks good  ", of: 7)

        store.send(.comment, on: 7)
        #expect(store.review(of: 7).isCommentBusy)
        try await waitUntil { store.busyComments.isEmpty && harness.spies.codeHost.calls.count == 5 }

        #expect(harness.spies.codeHost.calls.contains(.comment(iid: 7, body: "Looks good", repository: remote)))
        #expect(store.review(of: 7).commentDraft == "")
        #expect(harness.lastActivity?.title == "Commented on !7")
        #expect(harness.operations.latest(at: .pullRequest(7))?.title == "Comment on !7")
    }

    @Test func requestChangesKeepsTheDraftWhenItFails() async throws {
        script()
        await store.load(7)
        harness.spies.codeHost.actionError = PullRequestError.command("boom")
        store.setCommentDraft("Fix the test", of: 7)

        store.send(.requestChanges, on: 7)
        try await waitUntil { store.busyComments.isEmpty && harness.lastActivity?.outcome == .failure }

        #expect(harness.spies.codeHost.calls.last == .requestChanges(iid: 7, body: "Fix the test", repository: remote))
        #expect(store.review(of: 7).commentDraft == "Fix the test")
        #expect(harness.operations.latest(at: .pullRequest(7))?.failureMessage == "boom")
    }

    @Test func anEmptyDraftSendsNothing() {
        store.setCommentDraft("   ", of: 7)

        store.send(.comment, on: 7)

        #expect(store.busyComments.isEmpty)
        #expect(harness.spies.codeHost.calls.isEmpty)
    }

    @Test func aLineCommentSendsThePositionAndTheHeadCommit() async throws {
        script()
        await store.load(7)
        store.startLineComment(path: "a.swift", oldPath: "a.swift", lineID: 2, newLine: 4, oldLine: nil, of: 7)
        #expect(store.review(of: 7).lineComment?.lineID == 2)
        #expect(store.review(of: 8).lineComment == nil)

        store.setLineCommentText(" Rename this ")
        store.sendLineComment(headSHA: "abc123")
        try await waitUntil { store.isSendingLineComment == false && harness.spies.codeHost.calls.count == 5 }

        let comment = PullRequestLineComment(path: "a.swift", oldPath: "a.swift", newLine: 4, oldLine: nil, body: "Rename this", headSHA: "abc123")
        #expect(harness.spies.codeHost.calls.contains(.addLineComment(iid: 7, comment: comment, repository: remote)))
        #expect(store.lineComment == nil)
        #expect(harness.lastActivity?.title == "Commented on a.swift:4 in !7")
    }

    @Test func aFailedLineCommentKeepsTheTextAndCancelClearsIt() async throws {
        script()
        harness.spies.codeHost.actionError = PullRequestError.command("boom")
        store.startLineComment(path: "a.swift", oldPath: "a.swift", lineID: 2, newLine: 4, oldLine: nil, of: 7)
        store.setLineCommentText("Why?")

        store.sendLineComment(headSHA: nil)
        try await waitUntil { store.isSendingLineComment == false && harness.lastActivity?.outcome == .failure }
        #expect(store.lineComment?.text == "Why?")

        store.cancelLineComment()
        #expect(store.lineComment == nil)
    }

    @Test func aLineWithoutNumbersCannotBeCommented() {
        store.startLineComment(path: "a.swift", oldPath: "a.swift", lineID: 0, newLine: nil, oldLine: nil, of: 7)

        #expect(store.lineComment == nil)
    }

    @Test func aJobLogLoadsOnceAndTogglesOpen() async throws {
        script()
        harness.spies.codeHost.jobLogResult = .success("tail")

        store.toggleJobLog("71")
        try await waitUntil { store.jobLogs["71"] == .loaded("tail") }
        store.toggleJobLog("71")
        store.toggleJobLog("71")

        #expect(store.openJobLogs == ["71"])
        #expect(harness.spies.codeHost.calls == [.jobLog(jobID: "71", repository: remote)])
    }

    @Test func aFailedJobLogShowsTheError() async throws {
        script()
        harness.spies.codeHost.jobLogResult = .failure(PullRequestError.command("no log"))

        store.toggleJobLog("71")
        try await waitUntil { store.jobLogs["71"] == .failure("no log") }
    }

    @Test func retryRunsTheJobAgainAndReloads() async throws {
        script()
        await store.load(7)

        store.retryJob("71", named: "unit (test)", of: 7)
        try await waitUntil { store.busyJobs.isEmpty && harness.spies.codeHost.calls.count == 5 }

        #expect(harness.spies.codeHost.calls.contains(.retryJob(jobID: "71", repository: remote)))
        #expect(harness.lastActivity?.title == "Retried unit (test) of !7")
    }

    // MARK: Whole file

    private var summary: PullRequestSummary {
        PullRequestSummaryFixture.request(iid: 7, source: "feature/login", state: .opened, headSHA: "abc123")
    }

    @Test func showingTheWholeFileReadsItAtTheHeadCommitOnce() async throws {
        script()
        await store.load(7)
        harness.spies.codeHost.fileContentResult = .success("a\nb\n")

        store.toggleFullFile("a.swift", of: summary)
        try await waitUntil { store.review(of: 7).fileContents["a.swift"] == ["a", "b"] }
        store.toggleFullFile("a.swift", of: summary)
        store.toggleFullFile("a.swift", of: summary)

        #expect(store.review(of: 7).fullFiles == ["a.swift"])
        #expect(harness.spies.codeHost.calls.filter { $0 == .fileContent(path: "a.swift", ref: "abc123", repository: remote) }.count == 1)
    }

    @Test func aFailedFileReadIsLoggedAndTheFileStaysFolded() async throws {
        script()
        await store.load(7)
        harness.spies.codeHost.fileContentResult = .failure(PullRequestError.command("no file"))

        store.toggleFullFile("a.swift", of: summary)

        try await waitUntil { harness.lastActivity?.title == "Cannot read a.swift at abc123" }
        #expect(harness.lastActivity?.outcome == .failure)
        #expect(store.review(of: 7).fullFiles.isEmpty)
    }

    @Test func theFileLinkUsesTheHeadCommitOrTheBranch() async {
        script()
        await store.load(7)

        #expect(store.fileWebURL(path: "App/a.swift", line: 3, of: summary)?.absoluteString == "https://gitlab.example.com/team/app/-/blob/abc123/App/a.swift#L3")
        #expect(store.fileWebURL(path: "App/a.swift", line: nil, of: PullRequestSummaryFixture.request(iid: 7, source: "feature/login", state: .opened, headSHA: nil))?.absoluteString == "https://gitlab.example.com/team/app/-/blob/feature/login/App/a.swift")
    }

    @Test func theFileLinkIsMissingBeforeTheHostIsKnown() {
        #expect(store.fileWebURL(path: "App/a.swift", line: nil, of: summary) == nil)
    }

    // MARK: CircleCI

    private let workflowID = "11111111-2222-3333-4444-555555555555"

    private var ciDetails: PullRequestDetails {
        PullRequestDetails(
            description: "CI",
            threads: [],
            jobs: [
                PipelineJob(name: "ci/circleci: unit-tests", stage: nil, webURL: URL(string: "https://app.circleci.example.com/pipelines/github/example/app/42/workflows/\(workflowID)/jobs/7"), id: nil, status: .failed, ciWorkflowID: workflowID),
                PipelineJob(name: "lint", stage: "Check", webURL: nil, id: "9", status: .success),
            ]
        )
    }

    private var ciProject: CIProject {
        CIProject(checkoutPath: harness.worktrees.mainCheckoutPath, slug: "gh/example/app")
    }

    private func scriptCI() {
        script()
        harness.spies.codeHost.detailsResult = .success(ciDetails)
        harness.spies.tools.existingFiles = [CIPolicy.circleCIConfigPath(checkoutPath: harness.worktrees.mainCheckoutPath)]
        harness.spies.ci.workflowResult = .success(CIWorkflow(id: workflowID, name: "build-and-test", status: .failed, runID: "run-1", jobs: [
            CIJob(id: "job-unit", name: "unit-tests", status: .failed, isApproval: false),
            CIJob(id: "job-approve", name: "approve-release", status: .manual, isApproval: true),
        ]))
        harness.spies.ci.failedTestsResult = .success([CITestResult(className: "LoginTests", name: "testRetry", result: "failure", runTime: 1, message: "boom")])
        harness.spies.ci.flakyTestsResult = .success([CIFlakyTest(className: "LoginTests", name: "testRetry", jobName: "unit-tests", workflowName: "build-and-test", timesFlaked: 3)])
    }

    @Test func loadReadsTheCircleCIWorkflowItsFailedTestsAndTheFlakyList() async throws {
        scriptCI()

        await store.load(7)
        try await waitUntil { store.ciFlakyTests.isEmpty == false }

        #expect(store.ciToolState?.isLoggedIn == true)
        #expect(store.ciWorkflows[workflowID]?.name == "build-and-test")
        #expect(store.ciFailedTests["job-unit"]?.map(\.name) == ["testRetry"])
        #expect(harness.spies.ci.calls == [
            .toolState(project: ciProject),
            .workflow(id: workflowID, project: ciProject),
            .failedTests(jobID: "job-unit", project: ciProject),
            .flakyTests(project: ciProject),
        ])
        #expect(store.review(of: 7).hasCIProvider)
    }

    @Test func withoutTheConfigFileNoCircleCICallIsMade() async {
        scriptCI()
        harness.spies.tools.existingFiles = []

        await store.load(7)
        await harness.settle()

        #expect(harness.spies.ci.calls.isEmpty)
        #expect(store.review(of: 7).hasCIProvider == false)
    }

    @Test func theConfigKindTurnsTheDetectionOffAndOn() async throws {
        scriptCI()
        harness.spies.tools.existingFiles = []
        harness.spies.config.loadResult = ResolvedConfig(project: ProjectConfig(ci: CIConfig(kind: "circleci", project: "gh/example/app")), actions: [], tabs: [], issues: [], layers: [])
        await harness.config.reload()

        await store.load(7)
        try await waitUntil { store.ciWorkflows[workflowID] != nil }

        #expect(harness.spies.ci.calls.first == .toolState(project: ciProject))
    }

    @Test func aMissingToolStopsAfterTheToolCheck() async throws {
        scriptCI()
        harness.spies.ci.toolStateResult = .success(.missing)

        await store.load(7)
        try await waitUntil { store.ciToolState == .missing }
        await harness.settle()

        #expect(harness.spies.ci.calls == [.toolState(project: ciProject)])
        #expect(store.ciWorkflows.isEmpty)
    }

    @Test func aWorkflowReadFailureIsKeptAndLogged() async throws {
        scriptCI()
        harness.spies.ci.workflowResult = .failure(CIError.command("no workflow"))

        await store.load(7)
        try await waitUntil { store.ciWorkflowErrors[workflowID] == "no workflow" }

        #expect(harness.lastActivity?.outcome == .failure)
    }

    @Test func theLogOfACircleCIJobComesFromTheTool() async throws {
        scriptCI()
        harness.spies.ci.jobLogResult = .success("== Run tests\nfailed")
        await store.load(7)
        try await waitUntil { store.ciWorkflows[workflowID] != nil }

        store.toggleJobLog("job-unit")
        try await waitUntil { store.jobLogs["job-unit"] == .loaded("== Run tests\nfailed") }

        #expect(harness.spies.ci.calls.contains(.jobLog(jobID: "job-unit", project: ciProject)))
        #expect(harness.spies.codeHost.calls.contains { if case .jobLog = $0 { true } else { false } } == false)
    }

    @Test func retryOfACircleCIJobRerunsTheFailedJobsOfItsWorkflowAndReloads() async throws {
        scriptCI()
        await store.load(7)
        try await waitUntil { store.ciWorkflows[workflowID] != nil }

        store.retryJob("job-unit", named: "unit-tests", of: 7)
        try await waitUntil { store.ciBusyWorkflows.isEmpty && store.isLoaded(7) && store.ciWorkflows[workflowID] != nil }

        #expect(harness.spies.ci.calls.contains(.rerun(workflowID: workflowID, fromFailed: true, project: ciProject)))
        #expect(harness.activityTitles.contains("Re-ran the failed jobs of build-and-test"))
        #expect(harness.spies.ci.calls.filter { if case .workflow = $0 { true } else { false } }.count == 2)
    }

    @Test func cancelAndApproveGoToTheWorkflowAndItsRun() async throws {
        scriptCI()
        await store.load(7)
        try await waitUntil { store.ciWorkflows[workflowID] != nil }

        store.cancelWorkflow(workflowID, of: 7)
        try await waitUntil { store.ciBusyWorkflows.isEmpty && store.ciWorkflows[workflowID] != nil }
        store.approveJob("job-approve", named: "approve-release", of: 7)
        try await waitUntil { store.ciBusyWorkflows.isEmpty && harness.activityTitles.contains("Approved approve-release of build-and-test") }

        #expect(harness.spies.ci.calls.contains(.cancel(workflowID: workflowID, project: ciProject)))
        #expect(harness.spies.ci.calls.contains(.approve(runID: "run-1", job: "approve-release", project: ciProject)))
        #expect(harness.activityTitles.contains("Cancelled build-and-test"))
    }

    @Test func aFailedCircleCIActionIsLoggedAndClearsTheBusyFlag() async throws {
        scriptCI()
        harness.spies.ci.actionError = CIError.notLoggedIn
        await store.load(7)
        try await waitUntil { store.ciWorkflows[workflowID] != nil }

        store.rerunWorkflow(workflowID, fromFailed: false, of: 7)
        try await waitUntil { store.ciBusyWorkflows.isEmpty && harness.lastActivity?.title == "Re-ran build-and-test failed" }

        #expect(harness.lastActivity?.outcome == .failure)
        #expect(store.ciWorkflows[workflowID] != nil)
    }

    @Test func aProjectChangeForgetsTheCircleCIState() async throws {
        scriptCI()
        await store.load(7)
        try await waitUntil { store.ciWorkflows[workflowID] != nil }

        harness.events.post(.projectChanged)

        #expect(store.ciWorkflows.isEmpty)
        #expect(store.ciToolState == nil)
    }

    @Test func aLinkWithoutASlugFallsBackToTheGitHubRemote() async throws {
        scriptCI()
        harness.spies.git.webURLResult = CodeHost.gitHubSample.webURL
        harness.spies.codeHost.detailsResult = .success(PullRequestDetails(description: "CI", threads: [], jobs: [
            PipelineJob(name: "ci/circleci: unit-tests", stage: nil, webURL: URL(string: "https://app.circleci.example.com/workflow/\(workflowID)/job/22222222-3333-4444-5555-666666666666"), id: nil, status: .failed, ciWorkflowID: workflowID),
        ]))

        await store.load(7)
        try await waitUntil { store.ciFlakyTests.isEmpty == false }

        #expect(harness.spies.ci.calls.first == .toolState(project: CIProject(checkoutPath: harness.worktrees.mainCheckoutPath, slug: "gh/example/app")))
    }

    // MARK: CircleCI history and auto re-run

    @Test func aFinishedWorkflowIsKeptInTheHistoryButNotListedWhileCurrent() async throws {
        scriptCI()

        await store.load(7)
        try await waitUntil { harness.ciHistory.records(for: 7).first?.failedTestCount == 1 }

        #expect(harness.ciHistory.records(for: 7).map(\.id) == [workflowID])
        #expect(store.review(of: 7).ciHistory.isEmpty)
    }

    @Test func theHistoryListsTheEarlierWorkflows() async throws {
        scriptCI()
        let old = CIWorkflow(id: "old-workflow", name: "build-and-test", status: .failed, runID: nil, jobs: [])
        harness.ciHistory.remember(old, failedTests: [:], for: 7)

        await store.load(7)

        #expect(store.review(of: 7).ciHistory.map(\.id) == ["old-workflow"])
    }

    @Test func theHistoryOpensClosesAndForgets() {
        harness.ciHistory.remember(CIWorkflow(id: "old-workflow", name: "build", status: .failed, runID: nil, jobs: []), failedTests: [:], for: 7)

        store.toggleCIHistory(of: 7)
        let shown = store.review(of: 7).showsCIHistory
        store.clearCIHistory(of: 7)

        #expect(shown)
        #expect(store.review(of: 7).showsCIHistory == false)
        #expect(harness.ciHistory.records(for: 7).isEmpty)
    }

    @Test func aChecksChangedEventReloadsLoadedDetails() async throws {
        script()
        await store.load(7)

        harness.events.post(.pullRequestChecksChanged(iid: 7))
        harness.events.post(.pullRequestChecksChanged(iid: 8))

        try await waitUntil { harness.spies.codeHost.calls.filter { $0 == .details(iid: 7, repository: remote) }.count == 2 }
        #expect(harness.spies.codeHost.calls.contains(.details(iid: 8, repository: remote)) == false)
    }

    @Test func theReviewCarriesTheAutoRerunPlan() {
        let plan = CIAutoRerunPlan(iid: 7, maxAttempts: 5, attempts: 2, handledWorkflowIDs: [], lastRerunAt: nil)
        harness.store.encode([plan], forKey: PullRequestsPreferenceKeys.autoRerun(projectID: harness.session.selectedProjectID))

        #expect(store.review(of: 7).autoRerunPlan == plan)
        #expect(store.review(of: 8).autoRerunPlan == nil)
    }

    @Test func jobDetailsTestMessagesAndEarlierRunsOpenAndClose() {
        store.toggleJobDetails("job-unit")
        store.toggleTestMessage("job-unit/LoginTests.testRetry")
        store.toggleCIHistoryRun("old-workflow")
        let open = store.review(of: 7)
        store.toggleJobDetails("job-unit")

        #expect(open.openJobDetails == ["job-unit"])
        #expect(open.openTestMessages == ["job-unit/LoginTests.testRetry"])
        #expect(open.openCIHistoryRuns == ["old-workflow"])
        #expect(store.review(of: 7).openJobDetails.isEmpty)
    }

    @Test func aProjectChangeFoldsEverythingAgain() {
        store.toggleJobDetails("job-unit")
        store.toggleTestMessage("job-unit/LoginTests.testRetry")
        store.toggleCIHistoryRun("old-workflow")

        harness.events.post(.projectChanged)

        #expect(store.openJobDetails.isEmpty)
        #expect(store.openTestMessages.isEmpty)
        #expect(store.openCIHistoryRuns.isEmpty)
    }

    @Test func hideAndUnhideGoThroughTheProjectList() {
        store.hideFiles(["Podfile.lock", "Package.resolved"])
        let hidden = store.review(of: 7).chosenHiddenFiles
        store.unhideFile("Podfile.lock")

        #expect(hidden == ["Podfile.lock", "Package.resolved"])
        #expect(store.review(of: 8).chosenHiddenFiles == ["Package.resolved"])
        #expect(harness.pullRequestHiddenFiles.paths == ["Package.resolved"])
    }

    // MARK: Changed since your review

    private func edited(_ line: String) -> [PullRequestFileDiff] {
        [
            PullRequestFileDiff(oldPath: "a.swift", path: "a.swift", kind: .modified, additions: 1, deletions: 0, diff: GitDiff(lines: [line], droppedLines: 0, isBinary: false), isTooLarge: false),
            PullRequestFileDiff(oldPath: "b.swift", path: "b.swift", kind: .added, additions: 1, deletions: 0, diff: GitDiff(lines: ["+y"], droppedLines: 0, isBinary: false), isTooLarge: false),
        ]
    }

    @Test func aCommentSavesTheReviewAndANewCommitShowsTheChangedFiles() async throws {
        script()
        harness.spies.codeHost.diffsResult = .success(edited("+x"))
        await store.load(7)
        store.setCommentDraft("Looks good", of: 7)

        store.send(.comment, on: 7)
        try await waitUntil { store.busyComments.isEmpty && store.isLoaded(7) }
        let afterComment = store.review(of: 7)
        harness.spies.codeHost.diffsResult = .success(edited("+x2"))
        await store.reload(7)

        #expect(afterComment.reviewedAt == Date(timeIntervalSince1970: 1_800_000_000))
        #expect(afterComment.changedSinceReview.isEmpty)
        #expect(store.review(of: 7).changedSinceReview == ["a.swift"])
    }

    @Test func approvingSavesTheReviewOfTheLoadedDiff() async {
        script()
        await store.load(7)

        harness.events.post(.pullRequestReviewed(iid: 7))

        #expect(harness.pullRequestReviews.snapshot(of: 7)?.files.keys.sorted() == ["a.swift"])
    }

    @Test func markingEveryFileViewedSavesTheReview() async {
        script()
        harness.spies.codeHost.diffsResult = .success(edited("+x"))
        await store.load(7)

        store.toggleViewed("a.swift", of: 7)
        let afterOne = store.review(of: 7).reviewedAt
        store.toggleViewed("b.swift", of: 7)

        #expect(afterOne == nil)
        #expect(store.review(of: 7).reviewedAt != nil)
    }

    @Test func viewedMarksComeBackUntilTheFileChanges() async {
        script()
        harness.spies.codeHost.diffsResult = .success(edited("+x"))
        await store.load(7)
        store.toggleViewed("a.swift", of: 7)
        store.toggleViewed("b.swift", of: 7)
        harness.spies.codeHost.diffsResult = .success(edited("+x2"))

        await store.reload(7)

        #expect(store.review(of: 7).viewedFiles == ["b.swift"])
    }

    @Test func showOnlyChangedAndForget() async {
        script()
        await store.load(7)
        harness.events.post(.pullRequestReviewed(iid: 7))

        store.toggleOnlyChangedSinceReview(of: 7)
        let shown = store.review(of: 7).showsOnlyChangedSinceReview
        store.forgetReview(of: 7)

        #expect(shown)
        #expect(store.review(of: 7).showsOnlyChangedSinceReview == false)
        #expect(store.review(of: 7).reviewedAt == nil)
    }

    @Test func turnedOffNothingIsSavedAndViewedStaysForTheSession() async {
        harness.settings.values.remembersReviews = false
        script()
        await store.load(7)

        store.toggleViewed("a.swift", of: 7)
        harness.events.post(.pullRequestReviewed(iid: 7))
        await store.reload(7)

        #expect(harness.pullRequestReviews.snapshots.isEmpty)
        #expect(store.review(of: 7).viewedFiles == ["a.swift"])
        #expect(store.review(of: 7).reviewedAt == nil)
    }
}
