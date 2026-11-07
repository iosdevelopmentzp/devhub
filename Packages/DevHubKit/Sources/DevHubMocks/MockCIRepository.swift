import Foundation
import DevHubDomain

struct MockCIRepository: CIRepository {

    func toolState(project: CIProject) async throws -> CIToolState {
        MockData.ciToolState
    }

    func workflow(id: String, project: CIProject) async throws -> CIWorkflow {
        try? await Task.sleep(for: .milliseconds(200))
        return MockData.ciWorkflow
    }

    func workflowDetails(id: String, project: CIProject) async throws -> CIWorkflowDetails {
        MockData.ciWorkflowDetails
    }

    func workflows(runID: String, project: CIProject) async throws -> [CIWorkflow] {
        MockData.ciRunWorkflows
    }

    func branchRuns(branch: String, limit: Int, project: CIProject) async throws -> [CIRun] {
        Array(MockData.ciRuns.prefix(limit))
    }

    func jobLog(jobID: String, project: CIProject) async throws -> String {
        try? await Task.sleep(for: .milliseconds(200))
        return MockData.ciJobLog
    }

    func jobSteps(jobID: String, project: CIProject) async throws -> [CIJobStep] {
        MockData.ciJobSteps
    }

    func artifacts(jobID: String, project: CIProject) async throws -> [CIArtifact] {
        try? await Task.sleep(for: .milliseconds(200))
        return MockData.ciArtifacts
    }

    func downloadArtifacts(jobID: String, folderName: String, project: CIProject) async throws -> String {
        try? await Task.sleep(for: .milliseconds(300))
        return "~/Downloads/DevHub Artifacts/\(folderName)"
    }

    func failedTests(jobID: String, project: CIProject) async throws -> [CITestResult] {
        MockData.ciFailedTests
    }

    func flakyTests(project: CIProject) async throws -> [CIFlakyTest] {
        MockData.ciFlakyTests
    }

    func rerun(workflowID: String, fromFailed: Bool, project: CIProject) async throws {
        try? await Task.sleep(for: .milliseconds(300))
    }

    func cancel(workflowID: String, project: CIProject) async throws {
        try? await Task.sleep(for: .milliseconds(300))
    }

    func approve(runID: String, job: String, project: CIProject) async throws {
        try? await Task.sleep(for: .milliseconds(300))
    }
}
