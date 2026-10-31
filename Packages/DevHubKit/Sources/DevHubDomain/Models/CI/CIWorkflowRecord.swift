import Foundation

package struct CIWorkflowRecord: Identifiable, Hashable, Sendable, Codable {
    package let workflow: CIWorkflow
    package let failedTests: [String: [CITestResult]]
    package let recordedAt: Date

    package init(workflow: CIWorkflow, failedTests: [String: [CITestResult]], recordedAt: Date) {
        self.workflow = workflow
        self.failedTests = failedTests
        self.recordedAt = recordedAt
    }

    package var id: String {
        workflow.id
    }

    package var failedJobs: [CIJob] {
        workflow.jobs.filter { $0.status == .failed }
    }

    package var failedTestCount: Int {
        failedTests.values.reduce(0) { $0 + $1.count }
    }
}
