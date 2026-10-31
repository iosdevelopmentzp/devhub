import Foundation
import DevHubDomain
import DevHubUI

enum CIHistoryRowMapper {
    static func model(for record: CIWorkflowRecord, flaky: [CIFlakyTest], isOpen: Bool, openTestMessages: Set<String>, words: CodeHostWords) -> CIHistoryRowModel {
        let status = record.workflow.status
        let failedJobs = record.failedJobs.map { job in
            CIHistoryRowModel.FailedJob(
                id: job.id,
                title: job.name,
                tests: (record.failedTests[job.id] ?? []).map { PipelineJobRowMapper.failedTest($0, jobID: job.id, flaky: flaky, openMessages: openTestMessages) }
            )
        }
        return CIHistoryRowModel(
            id: record.id,
            title: record.workflow.name.isEmpty ? "CircleCI workflow" : record.workflow.name,
            statusTag: TagModel(
                PipelineJobRowMapper.ciStatusText(status, words: words),
                tint: PullRequestTagMapper.pipelineTint(status),
                systemImage: PullRequestTagMapper.pipelineIcon(status),
                hint: "The state of this workflow when DevHub last read it"
            ),
            timeText: record.recordedAt.relativeDescription,
            summaryText: summary(failedJobs: failedJobs.count, failedTests: record.failedTestCount),
            failedJobs: failedJobs,
            isOpen: isOpen && failedJobs.isEmpty == false,
            toggleHint: toggleHint(hasFailedJobs: failedJobs.isEmpty == false, isOpen: isOpen)
        )
    }

    static func summary(failedJobs: Int, failedTests: Int) -> String {
        guard failedJobs > 0 else { return "no failed jobs" }
        var parts = [CountText.count(failedJobs, "failed job", "failed jobs")]
        if failedTests > 0 {
            parts.append(CountText.count(failedTests, "failed test", "failed tests"))
        }
        return parts.joined(separator: " · ")
    }

    private static func toggleHint(hasFailedJobs: Bool, isOpen: Bool) -> String {
        guard hasFailedJobs else { return "This run has no failed jobs to show" }
        return isOpen ? "Hide the failed jobs" : "Show the failed jobs and tests of this run"
    }
}
