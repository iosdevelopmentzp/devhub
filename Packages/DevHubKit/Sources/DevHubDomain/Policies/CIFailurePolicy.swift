import Foundation

package enum CIFailurePolicy {

    package static func kind(of workflow: CIWorkflow, failedTests: [String: [CITestResult]], flaky: [CIFlakyTest]) -> CIFailureKind {
        let failedJobs = workflow.jobs.filter { $0.status == .failed }
        guard failedJobs.isEmpty == false else { return .noTests(job: workflow.name.isEmpty ? "The workflow" : workflow.name) }
        var total = 0
        for job in failedJobs {
            let tests = failedTests[job.id] ?? []
            guard tests.isEmpty == false else { return .noTests(job: job.name) }
            let real = tests.filter { FlakyTestPolicy.isFlaky($0, in: flaky) == false }
            guard real.isEmpty else { return .realTests(job: job.name, count: real.count) }
            total += tests.count
        }
        return .allFlaky(testCount: total)
    }
}
