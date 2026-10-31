import DevHubDomain
import Foundation

package final class SpyCIRepository: CIRepository, @unchecked Sendable {
    package enum Call: Hashable {
        case toolState(project: CIProject)
        case workflow(id: String, project: CIProject)
        case branchRuns(branch: String, limit: Int, project: CIProject)
        case jobLog(jobID: String, project: CIProject)
        case failedTests(jobID: String, project: CIProject)
        case flakyTests(project: CIProject)
        case rerun(workflowID: String, fromFailed: Bool, project: CIProject)
        case cancel(workflowID: String, project: CIProject)
        case approve(runID: String, job: String, project: CIProject)
    }

    private let lock = NSLock()
    private var _calls: [Call] = []
    private var _toolStateResult: Result<CIToolState, any Error> = .success(CIToolState(isInstalled: true, version: "1.13.0", isLoggedIn: true))
    private var _workflowResult: Result<CIWorkflow, any Error> = .success(CIWorkflow(id: "", name: "", status: .pending, runID: nil, jobs: []))
    private var _branchRunsResult: Result<[CIRun], any Error> = .success([])
    private var _jobLogResult: Result<String, any Error> = .success("")
    private var _failedTestsResult: Result<[CITestResult], any Error> = .success([])
    private var _flakyTestsResult: Result<[CIFlakyTest], any Error> = .success([])
    private var _actionError: (any Error)? = nil

    package init() {}

    package var calls: [Call] {
        lock.withLock { _calls }
    }

    package var toolStateResult: Result<CIToolState, any Error> {
        get { lock.withLock { _toolStateResult } }
        set { lock.withLock { _toolStateResult = newValue } }
    }

    package var workflowResult: Result<CIWorkflow, any Error> {
        get { lock.withLock { _workflowResult } }
        set { lock.withLock { _workflowResult = newValue } }
    }

    package var branchRunsResult: Result<[CIRun], any Error> {
        get { lock.withLock { _branchRunsResult } }
        set { lock.withLock { _branchRunsResult = newValue } }
    }

    package var jobLogResult: Result<String, any Error> {
        get { lock.withLock { _jobLogResult } }
        set { lock.withLock { _jobLogResult = newValue } }
    }

    package var failedTestsResult: Result<[CITestResult], any Error> {
        get { lock.withLock { _failedTestsResult } }
        set { lock.withLock { _failedTestsResult = newValue } }
    }

    package var flakyTestsResult: Result<[CIFlakyTest], any Error> {
        get { lock.withLock { _flakyTestsResult } }
        set { lock.withLock { _flakyTestsResult = newValue } }
    }

    package var actionError: (any Error)? {
        get { lock.withLock { _actionError } }
        set { lock.withLock { _actionError = newValue } }
    }

    package func toolState(project: CIProject) async throws -> CIToolState {
        try record(.toolState(project: project)) { try _toolStateResult.get() }
    }

    package func workflow(id: String, project: CIProject) async throws -> CIWorkflow {
        try record(.workflow(id: id, project: project)) { try _workflowResult.get() }
    }

    package func branchRuns(branch: String, limit: Int, project: CIProject) async throws -> [CIRun] {
        try record(.branchRuns(branch: branch, limit: limit, project: project)) { try _branchRunsResult.get() }
    }

    package func jobLog(jobID: String, project: CIProject) async throws -> String {
        try record(.jobLog(jobID: jobID, project: project)) { try _jobLogResult.get() }
    }

    package func failedTests(jobID: String, project: CIProject) async throws -> [CITestResult] {
        try record(.failedTests(jobID: jobID, project: project)) { try _failedTestsResult.get() }
    }

    package func flakyTests(project: CIProject) async throws -> [CIFlakyTest] {
        try record(.flakyTests(project: project)) { try _flakyTestsResult.get() }
    }

    package func rerun(workflowID: String, fromFailed: Bool, project: CIProject) async throws {
        try action(.rerun(workflowID: workflowID, fromFailed: fromFailed, project: project))
    }

    package func cancel(workflowID: String, project: CIProject) async throws {
        try action(.cancel(workflowID: workflowID, project: project))
    }

    package func approve(runID: String, job: String, project: CIProject) async throws {
        try action(.approve(runID: runID, job: job, project: project))
    }

    private func action(_ call: Call) throws {
        try record(call) {
            if let error = _actionError { throw error }
        }
    }

    private func record<Value>(_ call: Call, _ value: () throws -> Value) rethrows -> Value {
        try lock.withLock {
            _calls.append(call)
            return try value()
        }
    }
}
