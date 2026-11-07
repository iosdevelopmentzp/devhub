import Foundation
import Testing
import DevHubDomain
import DevHubTestSupport
@testable import DevHubMocks
@testable import DevHubPresentation

@Suite struct CIWorkflowHistoryTests {
    private let harness = StoreHarness()
    private let test = CITestResult(className: "LoginTests", name: "testRetry", result: "failure", runTime: 1, message: "boom")

    private var history: CIWorkflowHistory {
        harness.ciHistory
    }

    private var key: String {
        PullRequestsPreferenceKeys.ciHistory(projectID: harness.session.selectedProjectID, iid: 7)
    }

    private func workflow(_ id: String, status: CheckStatus = .failed) -> CIWorkflow {
        CIWorkflow(id: id, name: "build", status: status, runID: nil, jobs: [CIJob(id: "job-\(id)", name: "unit-tests", status: status, isApproval: false)])
    }

    @Test func aFinishedWorkflowIsSavedAndReadBack() {
        history.remember(workflow("w1"), failedTests: ["job-w1": [test]], for: 7)
        let reopened = StoreHarness(projects: [ProjectSample.app], store: harness.store)

        reopened.ciHistory.load(7)

        #expect(reopened.ciHistory.records(for: 7).map(\.id) == ["w1"])
        #expect(reopened.ciHistory.records(for: 7).first?.failedTests == ["job-w1": [test]])
    }

    @Test func aRunningWorkflowIsNotSaved() {
        history.remember(workflow("w1", status: .running), failedTests: [:], for: 7)

        #expect(history.records(for: 7).isEmpty)
        #expect(harness.store.data(forKey: key) == nil)
    }

    @Test func newerRunsComeFirst() {
        history.remember(workflow("w1"), failedTests: [:], for: 7)
        history.remember(workflow("w2"), failedTests: [:], for: 7)
        history.remember(workflow("w1"), failedTests: [:], for: 7)

        #expect(history.records(for: 7).map(\.id) == ["w2", "w1"])
    }

    @Test func clearRemovesTheSavedRuns() {
        history.remember(workflow("w1"), failedTests: [:], for: 7)

        history.clear(7)

        #expect(history.records(for: 7).isEmpty)
        #expect(harness.store.data(forKey: key) == nil)
    }

    @Test func aProjectChangeDropsTheRunsInMemory() {
        history.remember(workflow("w1"), failedTests: [:], for: 7)

        harness.events.post(.projectChanged)

        #expect(history.records.isEmpty)
    }

    private func run(_ id: String, status: CheckStatus) -> CIWorkflow {
        CIWorkflow(id: id, name: "build", status: status, runID: "pipeline-1", jobs: [CIJob(id: "job-\(id)", name: "unit-tests", status: status, isApproval: false)])
    }

    @Test func aTestThatPassesInARerunOfTheSameCommitFlakesOnce() {
        history.remember(run("w1", status: .failed), failedTests: ["job-w1": [test]], for: 7)

        history.remember(run("w2", status: .success), failedTests: [:], for: 7)
        history.remember(run("w2", status: .success), failedTests: [:], for: 7)

        #expect(harness.flakyTests.records.map(\.timesFlaked) == [1])
        #expect(history.flakyTests == [CIFlakyTest(className: "LoginTests", name: "testRetry", jobName: "unit-tests", workflowName: "build", timesFlaked: 1, source: .devhub)])
    }
}
