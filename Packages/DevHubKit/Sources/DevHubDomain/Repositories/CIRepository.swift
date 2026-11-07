import Foundation

package protocol CIRepository: Sendable {
    func toolState(project: CIProject) async throws -> CIToolState
    func workflow(id: String, project: CIProject) async throws -> CIWorkflow
    func workflowDetails(id: String, project: CIProject) async throws -> CIWorkflowDetails
    func workflows(runID: String, project: CIProject) async throws -> [CIWorkflow]
    func branchRuns(branch: String, limit: Int, project: CIProject) async throws -> [CIRun]
    func jobLog(jobID: String, project: CIProject) async throws -> String
    func jobSteps(jobID: String, project: CIProject) async throws -> [CIJobStep]
    func artifacts(jobID: String, project: CIProject) async throws -> [CIArtifact]
    func downloadArtifacts(jobID: String, folderName: String, project: CIProject) async throws -> String
    func failedTests(jobID: String, project: CIProject) async throws -> [CITestResult]
    func flakyTests(project: CIProject) async throws -> [CIFlakyTest]
    func rerun(workflowID: String, fromFailed: Bool, project: CIProject) async throws
    func cancel(workflowID: String, project: CIProject) async throws
    func approve(runID: String, job: String, project: CIProject) async throws
}
