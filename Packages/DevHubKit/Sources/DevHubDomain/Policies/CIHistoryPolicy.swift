import Foundation

package enum CIHistoryPolicy {
    package static let limit = 20
    package static let testLimit = 50
    package static let messageLimit = 4000

    package static func isRecordable(_ status: CheckStatus) -> Bool {
        PipelineStatePolicy.isActive(status) == false && status != .manual
    }

    package static func record(_ workflow: CIWorkflow, failedTests: [String: [CITestResult]], at date: Date) -> CIWorkflowRecord {
        let jobIDs = Set(workflow.jobs.map(\.id))
        var kept: [String: [CITestResult]] = [:]
        for (jobID, tests) in failedTests where jobIDs.contains(jobID) && tests.isEmpty == false {
            kept[jobID] = tests.prefix(testLimit).map(trimmed)
        }
        return CIWorkflowRecord(workflow: workflow, failedTests: kept, recordedAt: date)
    }

    package static func remember(_ record: CIWorkflowRecord, in records: [CIWorkflowRecord]) -> [CIWorkflowRecord] {
        guard let index = records.firstIndex(where: { $0.id == record.id }) else {
            return Array(([record] + records).prefix(limit))
        }
        var kept = records
        let old = records[index]
        kept[index] = CIWorkflowRecord(
            workflow: record.workflow,
            failedTests: record.failedTests.isEmpty ? old.failedTests : record.failedTests,
            recordedAt: old.recordedAt
        )
        return kept
    }

    package static func previous(in records: [CIWorkflowRecord], current: Set<String>) -> [CIWorkflowRecord] {
        records.filter { current.contains($0.id) == false }
    }

    private static func trimmed(_ test: CITestResult) -> CITestResult {
        guard let message = test.message, message.count > messageLimit else { return test }
        return CITestResult(className: test.className, name: test.name, result: test.result, runTime: test.runTime, message: String(message.prefix(messageLimit)) + "…")
    }
}
