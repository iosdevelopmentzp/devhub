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
    }

    @Test func theMockWorkflowHasAFailedJobAndAnApproval() {
        #expect(MockData.ciWorkflow.jobs.contains { $0.status == .failed })
        #expect(MockData.ciWorkflow.jobs.contains { $0.isApproval && $0.status == .manual })
        #expect(MockData.ciFlakyTests.allSatisfy { flaky in MockData.ciFailedTests.contains { $0.className == flaky.className && $0.name == flaky.name } })
    }
}
