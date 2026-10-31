import Foundation
import DevHubDomain

struct CircleCIRepository: CIRepository {
    let client: CircleCIClient

    func toolState(project: CIProject) async throws -> CIToolState {
        let versionResult: ShellResult
        do {
            versionResult = try await client.output(CircleCIClient.versionArguments(), project: project)
        } catch {
            return .missing
        }
        let version = CircleCIToolStateParser.version(from: versionResult)
        guard versionResult.exitCode == 0, let version, CIPolicy.isSupported(version: version) else {
            return CIToolState(isInstalled: true, version: version, isLoggedIn: false)
        }
        let settings = try? await client.output(CircleCIClient.settingArguments(), project: project)
        return CIToolState(isInstalled: true, version: version, isLoggedIn: settings.map(CircleCIToolStateParser.isLoggedIn) ?? false)
    }

    func workflow(id: String, project: CIProject) async throws -> CIWorkflow {
        let data = try await client.run(CircleCIClient.workflowArguments(id: id), project: project)
        return try CircleCIWorkflowParser.workflow(from: data, id: id)
    }

    func branchRuns(branch: String, limit: Int, project: CIProject) async throws -> [CIRun] {
        let data = try await client.run(CircleCIClient.runListArguments(branch: branch, limit: limit, slug: project.slug), project: project)
        return try CircleCIRunParser.runs(from: data)
    }

    func jobLog(jobID: String, project: CIProject) async throws -> String {
        let data = try await client.run(CircleCIClient.jobOutputArguments(jobID: jobID), project: project)
        return try CircleCIJobOutputParser.log(from: data)
    }

    func failedTests(jobID: String, project: CIProject) async throws -> [CITestResult] {
        let data = try await client.run(CircleCIClient.testResultArguments(jobID: jobID), project: project)
        return try CircleCITestResultParser.results(from: data)
    }

    func flakyTests(project: CIProject) async throws -> [CIFlakyTest] {
        guard let slug = project.slug, slug.isEmpty == false else { return [] }
        let data = try await client.run(CircleCIClient.flakyTestsArguments(slug: slug), project: project)
        return try CircleCIFlakyTestParser.tests(from: data)
    }

    func rerun(workflowID: String, fromFailed: Bool, project: CIProject) async throws {
        _ = try await client.run(CircleCIClient.rerunArguments(workflowID: workflowID, fromFailed: fromFailed), project: project)
    }

    func cancel(workflowID: String, project: CIProject) async throws {
        _ = try await client.run(CircleCIClient.cancelArguments(workflowID: workflowID), project: project)
    }

    func approve(runID: String, job: String, project: CIProject) async throws {
        _ = try await client.run(CircleCIClient.approveArguments(runID: runID, job: job, slug: project.slug), project: project)
    }
}
