import Foundation
import Testing
import DevHubDomain
import DevHubUI
@testable import DevHubPresentation

@Suite struct CIHistoryRowMapperTests {
    private let test = CITestResult(className: "LoginTests", name: "testRetry", result: "failure", runTime: 1, message: "boom")
    private let flaky = [CIFlakyTest(className: "LoginTests", name: "testRetry", jobName: "unit-tests", workflowName: "build", timesFlaked: 4)]

    private func record(name: String = "build", status: CheckStatus, jobs: [CIJob], tests: [String: [CITestResult]] = [:]) -> CIWorkflowRecord {
        CIWorkflowRecord(workflow: CIWorkflow(id: "w1", name: name, status: status, runID: nil, jobs: jobs), failedTests: tests, recordedAt: .now)
    }

    @Test func aFailedRunListsItsFailedJobsAndTests() throws {
        let jobs = [
            CIJob(id: "j1", name: "unit-tests", status: .failed, isApproval: false),
            CIJob(id: "j2", name: "lint", status: .success, isApproval: false),
        ]

        let model = CIHistoryRowMapper.model(for: record(status: .failed, jobs: jobs, tests: ["j1": [test]]), flaky: flaky, isOpen: false, openTestMessages: [], words: .gitHub)

        #expect(model.id == "w1")
        #expect(model.title == "build")
        #expect(model.statusTag.text == "failed")
        #expect(model.statusTag.tint == .red)
        #expect(model.timeText != nil)
        #expect(model.summaryText == "1 failed job · 1 failed test")
        #expect(model.failedJobs.map(\.title) == ["unit-tests"])
        let failed = try #require(model.failedJobs.first?.tests.first)
        #expect(failed.title == "LoginTests.testRetry")
        #expect(failed.message == "boom")
        #expect(failed.flakyText == "flaky · flaked 4 times")
        #expect(model.toggleHint == "Show the failed jobs and tests of this run")
    }

    @Test func aPassedRunHasNothingToOpen() {
        let model = CIHistoryRowMapper.model(for: record(status: .success, jobs: [CIJob(id: "j1", name: "unit-tests", status: .success, isApproval: false)]), flaky: [], isOpen: false, openTestMessages: [], words: .gitHub)

        #expect(model.statusTag.text == "passed")
        #expect(model.statusTag.tint == .green)
        #expect(model.summaryText == "no failed jobs")
        #expect(model.failedJobs.isEmpty)
        #expect(model.toggleHint == "This run has no failed jobs to show")
    }

    @Test func anOpenRunShowsItsJobsAndRemembersOpenMessages() {
        let jobs = [CIJob(id: "j1", name: "unit-tests", status: .failed, isApproval: false)]
        let failed = record(status: .failed, jobs: jobs, tests: ["j1": [test]])
        let passed = record(status: .success, jobs: [])

        let open = CIHistoryRowMapper.model(for: failed, flaky: [], isOpen: true, openTestMessages: ["j1/LoginTests.testRetry"], words: .gitHub)
        let empty = CIHistoryRowMapper.model(for: passed, flaky: [], isOpen: true, openTestMessages: [], words: .gitHub)

        #expect(open.isOpen)
        #expect(open.toggleHint == "Hide the failed jobs")
        #expect(open.failedJobs.first?.tests.map(\.isMessageOpen) == [true])
        #expect(empty.isOpen == false)
    }

    @Test func aRunWithoutANameGetsAPlainTitle() {
        let model = CIHistoryRowMapper.model(for: record(name: "", status: .canceled, jobs: []), flaky: [], isOpen: false, openTestMessages: [], words: .gitHub)

        #expect(model.title == "CircleCI workflow")
    }

    @Test func theSummaryCountsJobsAndTests() {
        #expect(CIHistoryRowMapper.summary(failedJobs: 2, failedTests: 0) == "2 failed jobs")
        #expect(CIHistoryRowMapper.summary(failedJobs: 2, failedTests: 5) == "2 failed jobs · 5 failed tests")
        #expect(CIHistoryRowMapper.summary(failedJobs: 0, failedTests: 0) == "no failed jobs")
    }
}
