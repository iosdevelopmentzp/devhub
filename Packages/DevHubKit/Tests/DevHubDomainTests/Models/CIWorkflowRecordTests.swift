import Foundation
import Testing
@testable import DevHubDomain

@Suite struct CIWorkflowRecordTests {
    private let test = CITestResult(className: "LoginTests", name: "testRetry", result: "failure", runTime: 1.5, message: "boom")

    private var record: CIWorkflowRecord {
        CIWorkflowRecord(
            workflow: CIWorkflow(id: "w1", name: "build", status: .other("failing"), runID: "run-1", jobs: [
                CIJob(id: "j1", name: "unit-tests", status: .failed, isApproval: false),
                CIJob(id: "j2", name: "lint", status: .success, isApproval: false),
                CIJob(id: "j3", name: "ui-tests", status: .failed, isApproval: false),
            ]),
            failedTests: ["j1": [test, test], "j3": [test]],
            recordedAt: Date(timeIntervalSince1970: 1_800_000_000)
        )
    }

    @Test func itCountsTheFailedJobsAndTests() {
        #expect(record.id == "w1")
        #expect(record.failedJobs.map(\.id) == ["j1", "j3"])
        #expect(record.failedTestCount == 3)
    }

    @Test func itSurvivesASaveAndARead() throws {
        let data = try JSONEncoder().encode(record)

        #expect(try JSONDecoder().decode(CIWorkflowRecord.self, from: data) == record)
    }
}
