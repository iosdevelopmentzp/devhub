import DevHubDomain
import Foundation
import Testing
@testable import DevHubMocks

@Suite struct MockCIRepositoryTests {
    private let project = CIProject(checkoutPath: "~/App", slug: nil)

    @Test func answersFromMockData() async throws {
        let repository = MockCIRepository()

        #expect(try await repository.toolState(project: project).isLoggedIn)
        #expect(try await repository.workflow(id: "x", project: project) == MockData.ciWorkflow)
        #expect(try await repository.branchRuns(branch: "main", limit: 1, project: project) == [MockData.ciRuns[0]])
        #expect(try await repository.failedTests(jobID: "x", project: project) == MockData.ciFailedTests)
        #expect(try await repository.flakyTests(project: project) == MockData.ciFlakyTests)
        #expect(try await repository.jobLog(jobID: "x", project: project).isEmpty == false)
        #expect(try await repository.workflowDetails(id: "x", project: project) == MockData.ciWorkflowDetails)
        #expect(try await repository.workflows(runID: "x", project: project) == MockData.ciRunWorkflows)
        #expect(try await repository.jobSteps(jobID: "x", project: project) == MockData.ciJobSteps)
        #expect(try await repository.artifacts(jobID: "x", project: project) == MockData.ciArtifacts)
        #expect(try await repository.downloadArtifacts(jobID: "x", folderName: "unit-tests 102", project: project) == "~/Downloads/DevHub Artifacts/unit-tests 102")
    }

    @Test func theMockDetailsCoverTheJobsOfTheMockWorkflow() {
        #expect(Set(MockData.ciWorkflowDetails.jobs.map(\.id)) == Set(MockData.ciWorkflow.jobs.map(\.id)))
        #expect(MockData.ciJobSteps.contains { $0.isFailed })
    }

    @Test func theMockWorkflowHasAFailedJobAndAnApproval() {
        #expect(MockData.ciWorkflow.jobs.contains { $0.status == .failed })
        #expect(MockData.ciWorkflow.jobs.contains { $0.isApproval && $0.status == .manual })
        #expect(MockData.ciFlakyTests.allSatisfy { flaky in MockData.ciFailedTests.contains { $0.className == flaky.className && $0.name == flaky.name } })
    }
}
