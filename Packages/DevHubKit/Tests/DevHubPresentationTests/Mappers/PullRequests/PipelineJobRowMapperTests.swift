import DevHubDomain
import DevHubUI
import Foundation
import Testing
@testable import DevHubPresentation

@Suite struct PipelineJobRowMapperTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)
    private let jobs = [
        PipelineJob(name: "lint", stage: nil, webURL: nil, id: "1", status: .success, duration: 40),
        PipelineJob(name: "unit", stage: "test", webURL: URL(string: "https://example.com/j/2"), id: "2", status: .failed, duration: 130, failureMessage: "script failure"),
        PipelineJob(name: "ui", stage: "test", webURL: nil, id: "3", status: .running),
        PipelineJob(name: "external", stage: nil, webURL: nil, id: nil, status: .failed),
    ]

    @Test func jobsAreGroupedByStageWithFailedFirst() {
        let groups = PipelineJobRowMapper.groups(for: jobs, review: .initial, words: .gitLab, now: now)

        #expect(groups.map(\.title) == ["other", "test"])
        #expect(groups[0].jobs.map(\.title) == ["external", "lint"])
        #expect(groups[0].tint == .red)
        #expect(groups[0].statusText == "1 failed")
        #expect(groups[1].jobs.map(\.title) == ["unit", "ui"])
        #expect(groups[1].statusText == "1 failed · 1 running")
        #expect(groups[1].icon == "xmark.circle.fill")
    }

    @Test func jobsWithoutStagesMakeOneGroupWithoutATitle() {
        let groups = PipelineJobRowMapper.groups(for: [jobs[0], jobs[3]], review: .initial, words: .gitHub, now: now)

        #expect(groups.count == 1)
        #expect(groups[0].title == nil)
        #expect(groups[0].jobs.map(\.title) == ["external", "lint"])
    }

    @Test func aGroupWithoutFailuresShowsItsState() {
        let passed = PipelineJobRowMapper.groups(for: [jobs[0]], review: .initial, words: .gitHub, now: now)
        let running = PipelineJobRowMapper.groups(for: [jobs[0], jobs[2]], review: .initial, words: .gitLab, now: now)

        #expect(passed[0].statusText == "passed")
        #expect(passed[0].tint == .green)
        #expect(running.map(\.title) == ["other", "test"])
        #expect(running[0].statusText == "success")
        #expect(running[1].statusText == "1 running")
        #expect(running[1].tint == .blue)
    }

    @Test func rowsCarryTheLogRetryAndDurationFacts() {
        let rows = PipelineJobRowMapper.groups(for: jobs, review: .initial, words: .gitLab, now: now).flatMap(\.jobs)

        #expect(rows.map(\.title) == ["external", "lint", "unit", "ui"])
        #expect(rows[2].tint == .red)
        #expect(rows[2].canRetry)
        #expect(rows[2].canShowLog)
        #expect(rows[2].durationText?.isEmpty == false)
        #expect(rows[2].failureText == "script failure")
        #expect(rows[0].canRetry == false)
        #expect(rows[0].canShowLog == false)
        #expect(rows[0].durationText == nil)
        #expect(rows[3].canShowLog == false)
        #expect(rows[3].canRetry == false)
        #expect(rows[1].canShowLog)
    }

    @Test func aFailureThatIsAllowedDoesNotCountAsFailed() {
        let allowed = PipelineJob(name: "lint", stage: "test", webURL: nil, id: "9", status: .failed, allowsFailure: true)

        let groups = PipelineJobRowMapper.groups(for: [allowed, jobs[0]], review: .initial, words: .gitLab, now: now)
        let row = PipelineJobRowMapper.model(for: allowed, index: 0, review: .initial, words: .gitLab)

        #expect(PipelineJobRowMapper.title(for: [allowed, jobs[0]], words: .gitLab) == "Pipeline 2")
        #expect(groups.map(\.tint) == [.green, .green])
        #expect(row.tint == .orange)
        #expect(row.allowedToFailText == "allowed to fail")
        #expect(row.canRetry)
    }

    @Test func theTitleCountsFailedAndRunningJobs() {
        #expect(PipelineJobRowMapper.title(for: jobs, words: .gitLab) == "Pipeline 4 · 2 failed · 1 running")
        #expect(PipelineJobRowMapper.title(for: [jobs[0]], words: .gitHub) == "Checks 1")
    }

    @Test func theRowShowsTheLogStateAndTheBusyFlag() {
        var review = PullRequestReviewState.initial
        review.openJobLogs = ["2"]
        review.jobLogs = ["2": .loaded("boom")]
        review.busyJobs = ["2"]

        let row = PipelineJobRowMapper.model(for: jobs[1], index: 1, review: review, words: .gitLab)

        #expect(row.isLogOpen)
        #expect(row.log == .loaded("boom"))
        #expect(row.isBusy)
        #expect(row.retryHint == "Run this job again")
    }

    // MARK: CircleCI

    private let workflowID = "11111111-2222-3333-4444-555555555555"

    private var workflow: CIWorkflow {
        CIWorkflow(id: workflowID, name: "build-and-test", status: .failed, runID: "run-1", jobs: [
            CIJob(id: "job-build", name: "build", status: .success, isApproval: false),
            CIJob(id: "job-unit", name: "unit-tests", status: .failed, isApproval: false),
            CIJob(id: "job-approve", name: "approve-release", status: .manual, isApproval: true),
        ])
    }

    private var ciJobs: [PipelineJob] {
        [
            PipelineJob(name: "ci/circleci: unit-tests", stage: nil, webURL: nil, id: nil, status: .failed, ciWorkflowID: workflowID),
            PipelineJob(name: "build-and-test - 1a2b3c4d", stage: nil, webURL: nil, id: nil, status: .failed, ciWorkflowID: workflowID),
            PipelineJob(name: "notes", stage: "Check", webURL: nil, id: "9", status: .success),
        ]
    }

    private func ciReview(toolState: CIToolState? = CIToolState(isInstalled: true, version: "1.13.0", isLoggedIn: true), loaded: Bool = true) -> PullRequestReviewState {
        var review = PullRequestReviewState.initial
        review.hasCIProvider = true
        review.ciToolState = toolState
        guard loaded else { return review }
        review.ciWorkflows = [workflowID: workflow]
        review.ciFailedTests = ["job-unit": [
            CITestResult(className: "LoginTests", name: "testRetry", result: "failure", runTime: 1, message: "boom"),
            CITestResult(className: "BadgeTests", name: "testCount", result: "failure", runTime: 1, message: nil),
        ]]
        review.ciFlakyTests = [CIFlakyTest(className: "LoginTests", name: "testRetry", jobName: "unit-tests", workflowName: "build-and-test", timesFlaked: 3)]
        return review
    }

    @Test func aLoadedWorkflowReplacesTheGitHubChecksThatPointAtIt() {
        let groups = PipelineJobRowMapper.groups(for: ciJobs, review: ciReview(), words: .gitHub, now: now)

        #expect(groups.map(\.title) == ["build-and-test", "Check"])
        #expect(groups[0].id == "circleci:\(workflowID)")
        #expect(groups[0].sourceText == "CircleCI")
        #expect(groups[0].jobs.map(\.title) == ["unit-tests", "approve-release", "build"])
        #expect(groups[0].statusText == "1 failed")
        #expect(groups[0].canRerunFailed)
        #expect(groups[0].canRerunAll)
        #expect(groups[0].canCancel == false)
        #expect(groups[1].jobs.map(\.title) == ["notes"])
    }

    @Test func aFailedCircleCIJobListsItsTestsWithTheFlakyTags() {
        let groups = PipelineJobRowMapper.groups(for: ciJobs, review: ciReview(), words: .gitHub, now: now)
        let unit = groups[0].jobs[0]

        #expect(unit.flakyTag?.text == "1 of 2 flaky")
        #expect(unit.flakyTag?.tint == .orange)
        #expect(unit.failedTests.map(\.title) == ["LoginTests.testRetry", "BadgeTests.testCount"])
        #expect(unit.failedTests.map(\.flakyText) == ["flaky · flaked 3 times", nil])
        #expect(unit.failedTests[0].message == "boom")
        #expect(unit.canRetry)
        #expect(unit.canShowLog)
        #expect(unit.canApprove == false)
        #expect(unit.retryHint.contains("build-and-test"))
    }

    @Test func theFailureMessageOfAJobIsFoldedUntilOpened() {
        let folded = PipelineJobRowMapper.groups(for: jobs, review: .initial, words: .gitLab, now: now).flatMap(\.jobs)
        var review = PullRequestReviewState.initial
        review.openJobDetails = ["2"]
        let open = PipelineJobRowMapper.groups(for: jobs, review: review, words: .gitLab, now: now).flatMap(\.jobs)

        #expect(folded[2].detailsTitle == "reason")
        #expect(folded[2].isDetailsOpen == false)
        #expect(folded[2].detailsHint == "Show why this job failed")
        #expect(folded[1].detailsTitle == nil)
        #expect(open[2].isDetailsOpen)
        #expect(open[2].detailsHint == "Hide the failure message")
    }

    @Test func theFailedTestsOfACircleCIJobAreFoldedUntilOpened() {
        var review = ciReview()
        let folded = PipelineJobRowMapper.groups(for: ciJobs, review: review, words: .gitHub, now: now)[0].jobs[0]
        review.openJobDetails = ["job-unit"]
        review.openTestMessages = ["job-unit/LoginTests.testRetry"]
        let open = PipelineJobRowMapper.groups(for: ciJobs, review: review, words: .gitHub, now: now)[0].jobs[0]

        #expect(folded.detailsTitle == "2 failed tests")
        #expect(folded.isDetailsOpen == false)
        #expect(folded.failedTests.map(\.id) == ["job-unit/LoginTests.testRetry", "job-unit/BadgeTests.testCount"])
        #expect(folded.failedTests.allSatisfy { $0.isMessageOpen == false })
        #expect(open.isDetailsOpen)
        #expect(open.detailsHint == "Hide the failed tests")
        #expect(open.failedTests.map(\.isMessageOpen) == [true, false])
    }

    @Test func anApprovalJobOnHoldCanBeApproved() {
        let groups = PipelineJobRowMapper.groups(for: ciJobs, review: ciReview(), words: .gitHub, now: now)
        let approval = groups[0].jobs[1]

        #expect(approval.statusText == "waiting for approval")
        #expect(approval.canApprove)
        #expect(approval.canShowLog == false)
        #expect(approval.canRetry == false)
    }

    @Test func anApprovalWithoutARunIDCannotBeApproved() {
        var review = ciReview()
        review.ciWorkflows = [workflowID: CIWorkflow(id: workflowID, name: "build-and-test", status: .manual, runID: nil, jobs: workflow.jobs)]

        let group = PipelineJobRowMapper.groups(for: ciJobs, review: review, words: .gitHub, now: now)[0]

        #expect(group.jobs[1].canApprove == false)
        #expect(group.statusText == "1 failed")
        #expect(group.canCancel)
    }

    @Test func aRunningWorkflowCanBeCancelledButNotRerun() {
        var review = ciReview()
        review.ciWorkflows = [workflowID: CIWorkflow(id: workflowID, name: "build-and-test", status: .running, runID: "run-1", jobs: [CIJob(id: "j", name: "build", status: .running, isApproval: false)])]

        let group = PipelineJobRowMapper.groups(for: ciJobs, review: review, words: .gitHub, now: now)[0]

        #expect(group.canCancel)
        #expect(group.canRerunAll == false)
        #expect(group.canRerunFailed == false)
        #expect(group.statusText == "1 running")
        #expect(group.jobs[0].canShowLog == false)
    }

    @Test func aBusyWorkflowHidesItsActions() {
        var review = ciReview()
        review.ciBusyWorkflows = [workflowID]

        let group = PipelineJobRowMapper.groups(for: ciJobs, review: review, words: .gitHub, now: now)[0]

        #expect(group.isBusy)
        #expect(group.canRerunFailed == false)
        #expect(group.jobs[0].isBusy)
        #expect(group.jobs[0].canRetry == false)
        #expect(group.jobs[1].canApprove == false)
    }

    @Test func gitHubRowsKeepANoteWhileTheWorkflowIsNotLoaded() {
        let reading = PipelineJobRowMapper.groups(for: ciJobs, review: ciReview(loaded: false), words: .gitHub, now: now)
        var failed = ciReview(loaded: false)
        failed.ciWorkflowErrors = [workflowID: "no workflow"]
        let withError = PipelineJobRowMapper.groups(for: ciJobs, review: failed, words: .gitHub, now: now)
        let notInstalled = PipelineJobRowMapper.groups(for: ciJobs, review: ciReview(toolState: .missing, loaded: false), words: .gitHub, now: now)
        let noProvider = PipelineJobRowMapper.groups(for: ciJobs, review: .initial, words: .gitHub, now: now)

        #expect(reading.map(\.title) == ["other", "Check"])
        #expect(reading[0].jobs.map(\.noteText) == ["Reading the CircleCI workflow…", "Reading the CircleCI workflow…"])
        #expect(withError[0].jobs.map(\.noteText) == ["CircleCI: no workflow", "CircleCI: no workflow"])
        #expect(notInstalled[0].jobs.map(\.noteText) == [nil, nil])
        #expect(noProvider[0].jobs.map(\.noteText) == [nil, nil])
    }

    @Test func theFlakyTagNamesTheCount() {
        #expect(PipelineJobRowMapper.flakyTag(flakyCount: 0, failedCount: 2) == nil)
        #expect(PipelineJobRowMapper.flakyTag(flakyCount: 2, failedCount: 2)?.text == "flaky")
        #expect(PipelineJobRowMapper.flakyTag(flakyCount: 1, failedCount: 1)?.hint == "The failed test is flaky: it passed on a re-run before (CircleCI Insights)")
        #expect(PipelineJobRowMapper.flakyTag(flakyCount: 1, failedCount: 3)?.text == "1 of 3 flaky")
    }

    @Test func aCircleCIJobShowsItsDurationLinkFailedStepAndSteps() {
        var review = ciReview()
        review.ciWorkflowDetails = [workflowID: CIWorkflowDetails(id: workflowID, pipelineNumber: 42, projectSlug: nil, createdAt: nil, stoppedAt: nil, jobs: [
            CIJobDetails(id: "job-unit", number: 102, startedAt: now.addingTimeInterval(-505), stoppedAt: now, approvalRequestID: nil),
            CIJobDetails(id: "job-build", number: 101, startedAt: now.addingTimeInterval(-60), stoppedAt: nil, approvalRequestID: nil),
        ])]
        review.ciJobSteps = ["job-unit": [
            CIJobStep(index: 0, name: "Checkout", status: .success, duration: 8, exitCode: 0),
            CIJobStep(index: 1, name: "Run tests", status: .failed, duration: 452, exitCode: 65),
        ]]
        let linked = [PipelineJob(name: "ci/circleci: unit-tests", stage: nil, webURL: URL(string: "https://app.circleci.example.com/pipelines/github/example/app/42/workflows/\(workflowID)/jobs/7"), id: nil, status: .failed, ciWorkflowID: workflowID)]

        let rows = PipelineJobRowMapper.groups(for: linked, review: review, words: .gitHub, now: now)[0].jobs
        let unit = rows[0]
        let build = rows.first { $0.title == "build" }

        #expect(unit.durationText == DurationFormat.text(505))
        #expect(unit.url?.absoluteString == "https://app.circleci.example.com/pipelines/github/example/app/42/workflows/\(workflowID)/jobs/102")
        #expect(unit.failureText == "Run tests failed (exit 65)")
        #expect(unit.steps.map(\.title) == ["Checkout", "Run tests"])
        #expect(unit.steps[1].exitText == "exit 65")
        #expect(unit.steps[1].tint == .red)
        #expect(unit.steps[0].durationText == DurationFormat.text(8))
        #expect(unit.detailsTitle == "2 failed tests")
        #expect(unit.detailsHint == "Show the failed step, the steps of this job and its failed tests")
        #expect(unit.logHint == PipelineJobRowMapper.circleCILogHint)
        #expect(build?.durationText == DurationFormat.text(60))
        #expect(build?.url?.absoluteString.hasSuffix("/jobs/101") == true)
        #expect(build?.steps.isEmpty == true)
        #expect(build?.detailsTitle == nil)
    }

    @Test func withoutTheDetailsTheRowHasNoDurationOrLink() {
        let unit = PipelineJobRowMapper.groups(for: ciJobs, review: ciReview(), words: .gitHub, now: now)[0].jobs[0]

        #expect(unit.durationText == nil)
        #expect(unit.url == nil)
        #expect(unit.failureText == nil)
        #expect(unit.canShowArtifacts)
    }

    @Test func aFailedStepWithoutTestsIsTheReason() {
        var review = ciReview()
        review.ciFailedTests = [:]
        review.ciJobSteps = ["job-unit": [CIJobStep(index: 0, name: "Build", status: .failed, duration: nil, exitCode: nil)]]

        let unit = PipelineJobRowMapper.groups(for: ciJobs, review: review, words: .gitHub, now: now)[0].jobs[0]

        #expect(unit.detailsTitle == "reason")
        #expect(unit.failureText == "Build failed")
        #expect(unit.detailsHint == "Show the steps of this job and the one that failed")
    }

    @Test func theArtifactsAndTheDownloadStatesMapToTheRow() {
        var review = ciReview()
        review.openJobArtifacts = ["job-unit"]
        review.ciArtifacts = ["job-unit": .loaded([CIArtifact(path: "a/b.txt", url: URL(string: "https://app.circleci.example.com/a/b.txt"))]), "job-build": .failure("no")]
        review.ciDownloads = ["job-unit": .done(folder: "/tmp/x")]

        let rows = PipelineJobRowMapper.groups(for: ciJobs, review: review, words: .gitHub, now: now)[0].jobs
        let unit = rows[0]
        let build = rows.first { $0.title == "build" }
        let approve = rows.first { $0.title == "approve-release" }

        #expect(unit.isArtifactsOpen)
        #expect(unit.artifacts == .loaded([PipelineJobRowModel.ArtifactRow(id: "a/b.txt", path: "a/b.txt", url: URL(string: "https://app.circleci.example.com/a/b.txt"))]))
        #expect(unit.downloadTitle == nil)
        #expect(unit.downloadFolder == "/tmp/x")
        #expect(build?.artifacts == .failure("no"))
        #expect(build?.downloadTitle == "Download All")
        #expect(approve?.canShowArtifacts == false)

        review.ciDownloads = ["job-unit": .downloading]
        #expect(PipelineJobRowMapper.groups(for: ciJobs, review: review, words: .gitHub, now: now)[0].jobs[0].downloadTitle == "Downloading…")
        review.ciDownloads = ["job-unit": .failure("disk full")]
        let failed = PipelineJobRowMapper.groups(for: ciJobs, review: review, words: .gitHub, now: now)[0].jobs[0]
        #expect(failed.downloadTitle == "Download All")
        #expect(failed.downloadFailure == "disk full")
    }

    @Test func aFlakyTestFoundByDevHubSaysSo() {
        let devhub = CIFlakyTest(className: "A", name: "b", jobName: nil, workflowName: nil, timesFlaked: 2, source: .devhub)
        let insights = CIFlakyTest(className: "A", name: "b", jobName: nil, workflowName: nil, timesFlaked: 1)

        #expect(PipelineJobRowMapper.flakyText(devhub) == "flaky · flaked 2 times (DevHub)")
        #expect(PipelineJobRowMapper.flakyText(insights) == "flaky · flaked 1 time")
    }
}
