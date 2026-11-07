import Foundation
import Testing
@testable import DevHubDomain

@Suite struct FlakyTrackingPolicyTests {
    private let test = CITestResult(className: "LoginTests", name: "testRetry", result: "failure", runTime: 1, message: "boom")
    private let other = CITestResult(className: "FeedTests", name: "testScroll", result: "failure", runTime: 1, message: nil)
    private let date = Date(timeIntervalSince1970: 1_000)

    private func record(_ id: String, run: String?, status: CheckStatus, jobs: [(String, CheckStatus)], failed: [String: [CITestResult]] = [:]) -> CIWorkflowRecord {
        let workflow = CIWorkflow(id: id, name: "build", status: status, runID: run, jobs: jobs.map { CIJob(id: "\(id)-\($0.0)", name: $0.0, status: $0.1, isApproval: false) })
        return CIWorkflowRecord(workflow: workflow, failedTests: failed, recordedAt: date)
    }

    @Test func aTestFlakesWhenItsJobPassesInTheSameRun() {
        let failed = record("w1", run: "p1", status: .failed, jobs: [("unit", .failed)], failed: ["w1-unit": [test]])
        let passed = record("w2", run: "p1", status: .success, jobs: [("unit", .success)])

        #expect(FlakyTrackingPolicy.flakes(new: passed, earlier: [failed]) == [CIFlakyTest(className: "LoginTests", name: "testRetry", jobName: "unit", workflowName: "build", timesFlaked: 1, source: .devhub)])
    }

    @Test func aPassedJobInAFailedWorkflowCountsToo() {
        let failed = record("w1", run: "p1", status: .failed, jobs: [("unit", .failed), ("ui", .failed)], failed: ["w1-unit": [test], "w1-ui": [other]])
        let rerun = record("w2", run: "p1", status: .failed, jobs: [("unit", .success), ("ui", .failed)], failed: ["w2-ui": [other]])

        #expect(FlakyTrackingPolicy.flakes(new: rerun, earlier: [failed]).map(\.name) == ["testRetry"])
    }

    @Test func anotherRunOrAStillFailingTestIsNoFlake() {
        let failed = record("w1", run: "p1", status: .failed, jobs: [("unit", .failed)], failed: ["w1-unit": [test]])
        let otherRun = record("w2", run: "p2", status: .success, jobs: [("unit", .success)])
        let noRun = record("w3", run: nil, status: .success, jobs: [("unit", .success)])
        let stillFailing = record("w4", run: "p1", status: .failed, jobs: [("unit", .failed)], failed: ["w4-unit": [test]])

        #expect(FlakyTrackingPolicy.flakes(new: otherRun, earlier: [failed]).isEmpty)
        #expect(FlakyTrackingPolicy.flakes(new: noRun, earlier: [failed]).isEmpty)
        #expect(FlakyTrackingPolicy.flakes(new: stillFailing, earlier: [failed]).isEmpty)
    }

    @Test func addCountsAgainAndKeepsTheNewestFirst() {
        let flake = CIFlakyTest(className: "LoginTests", name: "testRetry", jobName: "unit", workflowName: "build", timesFlaked: 1, source: .devhub)
        let second = CIFlakyTest(className: "FeedTests", name: "testScroll", jobName: nil, workflowName: nil, timesFlaked: 1, source: .devhub)

        let once = FlakyTrackingPolicy.add([flake], to: [], at: date)
        let twice = FlakyTrackingPolicy.add([flake, second], to: once, at: date.addingTimeInterval(60))

        #expect(twice.map(\.name) == ["testRetry", "testScroll"])
        #expect(twice.map(\.timesFlaked) == [2, 1])
        #expect(twice.first?.lastFlakedAt == date.addingTimeInterval(60))
        #expect(FlakyTrackingPolicy.tests(twice).allSatisfy { $0.source == .devhub })
    }

    @Test func theHigherCountWinsTheMerge() {
        let insights = [CIFlakyTest(className: "LoginTests", name: "testRetry", jobName: "unit", workflowName: "build", timesFlaked: 5)]
        let ledger = [
            CIFlakyTest(className: "LoginTests", name: "testRetry", jobName: "unit", workflowName: "build", timesFlaked: 2, source: .devhub),
            CIFlakyTest(className: "FeedTests", name: "testScroll", jobName: nil, workflowName: nil, timesFlaked: 3, source: .devhub),
        ]

        let merged = FlakyTrackingPolicy.merged(insights: insights, ledger: ledger)

        #expect(merged.map(\.name) == ["testScroll", "testRetry"])
        #expect(merged.map(\.source) == [.devhub, .insights])
    }
}
