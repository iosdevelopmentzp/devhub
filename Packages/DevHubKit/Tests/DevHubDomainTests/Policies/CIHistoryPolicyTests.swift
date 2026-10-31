import Foundation
import Testing
@testable import DevHubDomain

@Suite struct CIHistoryPolicyTests {
    private let date = Date(timeIntervalSince1970: 1_800_000_000)
    private let test = CITestResult(className: "LoginTests", name: "testRetry", result: "failure", runTime: 1, message: "boom")

    private func workflow(_ id: String, status: CheckStatus = .failed) -> CIWorkflow {
        CIWorkflow(id: id, name: "build", status: status, runID: nil, jobs: [CIJob(id: "job-\(id)", name: "unit-tests", status: status, isApproval: false)])
    }

    @Test func onlyAFinishedWorkflowIsKept() {
        #expect(CIHistoryPolicy.isRecordable(.failed))
        #expect(CIHistoryPolicy.isRecordable(.success))
        #expect(CIHistoryPolicy.isRecordable(.canceled))
        #expect(CIHistoryPolicy.isRecordable(.running) == false)
        #expect(CIHistoryPolicy.isRecordable(.pending) == false)
        #expect(CIHistoryPolicy.isRecordable(.manual) == false)
    }

    @Test func aRecordKeepsTheFailedTestsOfItsOwnJobs() {
        let record = CIHistoryPolicy.record(workflow("w1"), failedTests: ["job-w1": [test], "job-w2": [test], "job-empty": []], at: date)

        #expect(record.failedTests == ["job-w1": [test]])
        #expect(record.recordedAt == date)
    }

    @Test func aRecordCutsLongMessagesAndLongLists() throws {
        let long = CITestResult(className: "A", name: "b", result: "failure", runTime: nil, message: String(repeating: "x", count: CIHistoryPolicy.messageLimit + 10))
        let many = Array(repeating: long, count: CIHistoryPolicy.testLimit + 5)

        let record = CIHistoryPolicy.record(workflow("w1"), failedTests: ["job-w1": many], at: date)
        let tests = try #require(record.failedTests["job-w1"])

        #expect(tests.count == CIHistoryPolicy.testLimit)
        #expect(tests.first?.message?.count == CIHistoryPolicy.messageLimit + 1)
        #expect(tests.first?.message?.hasSuffix("…") == true)
    }

    @Test func aNewWorkflowGoesFirstAndTheListStaysShort() {
        let records = (0..<CIHistoryPolicy.limit).map { CIWorkflowRecord(workflow: workflow("old\($0)"), failedTests: [:], recordedAt: date) }
        let new = CIWorkflowRecord(workflow: workflow("new"), failedTests: [:], recordedAt: date)

        let kept = CIHistoryPolicy.remember(new, in: records)

        #expect(kept.count == CIHistoryPolicy.limit)
        #expect(kept.first?.id == "new")
        #expect(kept.last?.id == "old\(CIHistoryPolicy.limit - 2)")
    }

    @Test func aKnownWorkflowKeepsItsPlaceItsTimeAndItsTests() {
        let first = CIWorkflowRecord(workflow: workflow("w1"), failedTests: ["job-w1": [test]], recordedAt: date)
        let other = CIWorkflowRecord(workflow: workflow("w0"), failedTests: [:], recordedAt: date)
        let again = CIWorkflowRecord(workflow: workflow("w1", status: .canceled), failedTests: [:], recordedAt: date.addingTimeInterval(60))

        let kept = CIHistoryPolicy.remember(again, in: [other, first])

        #expect(kept.map(\.id) == ["w0", "w1"])
        #expect(kept[1].recordedAt == date)
        #expect(kept[1].workflow.status == .canceled)
        #expect(kept[1].failedTests == ["job-w1": [test]])
    }

    @Test func thePreviousRunsLeaveOutTheCurrentWorkflows() {
        let records = ["w1", "w2", "w3"].map { CIWorkflowRecord(workflow: workflow($0), failedTests: [:], recordedAt: date) }

        #expect(CIHistoryPolicy.previous(in: records, current: ["w2"]).map(\.id) == ["w1", "w3"])
    }
}
