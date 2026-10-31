import DevHubDomain
import DevHubUI
import Foundation
import Testing
@testable import DevHubPresentation

@Suite struct PipelineJobRowMapperTests {
    private let jobs = [
        PipelineJob(name: "lint", stage: nil, webURL: nil, id: "1", status: .success, duration: 40),
        PipelineJob(name: "unit", stage: "test", webURL: URL(string: "https://example.com/j/2"), id: "2", status: .failed, duration: 130, failureMessage: "script failure"),
        PipelineJob(name: "ui", stage: "test", webURL: nil, id: "3", status: .running),
        PipelineJob(name: "external", stage: nil, webURL: nil, id: nil, status: .failed),
    ]

    @Test func jobsAreGroupedByStageWithFailedFirst() {
        let groups = PipelineJobRowMapper.groups(for: jobs, review: .initial, words: .gitLab)

        #expect(groups.map(\.title) == ["other", "test"])
        #expect(groups[0].jobs.map(\.title) == ["external", "lint"])
        #expect(groups[0].tint == .red)
        #expect(groups[0].statusText == "1 failed")
        #expect(groups[1].jobs.map(\.title) == ["unit", "ui"])
        #expect(groups[1].statusText == "1 failed · 1 running")
        #expect(groups[1].icon == "xmark.circle.fill")
    }

    @Test func jobsWithoutStagesMakeOneGroupWithoutATitle() {
        let groups = PipelineJobRowMapper.groups(for: [jobs[0], jobs[3]], review: .initial, words: .gitHub)

        #expect(groups.count == 1)
        #expect(groups[0].title == nil)
        #expect(groups[0].jobs.map(\.title) == ["external", "lint"])
    }

    @Test func aGroupWithoutFailuresShowsItsState() {
        let passed = PipelineJobRowMapper.groups(for: [jobs[0]], review: .initial, words: .gitHub)
        let running = PipelineJobRowMapper.groups(for: [jobs[0], jobs[2]], review: .initial, words: .gitLab)

        #expect(passed[0].statusText == "passed")
        #expect(passed[0].tint == .green)
        #expect(running.map(\.title) == ["other", "test"])
        #expect(running[0].statusText == "success")
        #expect(running[1].statusText == "1 running")
        #expect(running[1].tint == .blue)
    }

    @Test func rowsCarryTheLogRetryAndDurationFacts() {
        let rows = PipelineJobRowMapper.groups(for: jobs, review: .initial, words: .gitLab).flatMap(\.jobs)

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

        let groups = PipelineJobRowMapper.groups(for: [allowed, jobs[0]], review: .initial, words: .gitLab)
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
}
