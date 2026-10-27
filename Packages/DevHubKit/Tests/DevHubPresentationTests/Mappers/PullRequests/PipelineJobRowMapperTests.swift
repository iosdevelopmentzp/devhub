import DevHubDomain
import DevHubUI
import Foundation
import Testing
@testable import DevHubPresentation

@Suite struct PipelineJobRowMapperTests {
    private let jobs = [
        PipelineJob(name: "lint", stage: nil, webURL: nil, id: "1", status: .success),
        PipelineJob(name: "unit", stage: "test", webURL: URL(string: "https://example.com/j/2"), id: "2", status: .failed),
        PipelineJob(name: "ui", stage: "test", webURL: nil, id: "3", status: .running),
        PipelineJob(name: "external", stage: nil, webURL: nil, id: nil, status: .failed),
    ]

    @Test func failedJobsComeFirstThenRunningThenPassed() {
        let rows = PipelineJobRowMapper.rows(for: jobs, review: .initial, words: .gitLab)

        #expect(rows.map(\.title) == ["unit (test)", "external", "ui (test)", "lint"])
        #expect(rows[0].tint == .red)
        #expect(rows[0].canRetry)
        #expect(rows[0].canShowLog)
        #expect(rows[1].canRetry == false)
        #expect(rows[1].canShowLog == false)
        #expect(rows[2].canShowLog == false)
        #expect(rows[2].canRetry == false)
        #expect(rows[3].canShowLog)
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
