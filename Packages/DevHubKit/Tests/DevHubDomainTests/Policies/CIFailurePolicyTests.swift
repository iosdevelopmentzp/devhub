import Foundation
import Testing
@testable import DevHubDomain

@Suite struct CIFailurePolicyTests {
    private let flaky = [CIFlakyTest(className: "LoginTests", name: "testRetry", jobName: "unit-tests", workflowName: "build-and-test", timesFlaked: 3)]
    private let unitTests = CIJob(id: "j1", name: "unit-tests", status: .failed, isApproval: false)
    private let build = CIJob(id: "j2", name: "build", status: .failed, isApproval: false)

    private func workflow(_ jobs: [CIJob]) -> CIWorkflow {
        CIWorkflow(id: "w1", name: "build-and-test", status: .failed, runID: nil, jobs: jobs)
    }

    private func test(_ name: String) -> CITestResult {
        CITestResult(className: "LoginTests", name: name, result: "failure", runTime: 1, message: nil)
    }

    @Test func everyFailedTestFlakyMeansTheFailureIsFlaky() {
        let passed = CIJob(id: "j0", name: "lint", status: .success, isApproval: false)

        let kind = CIFailurePolicy.kind(of: workflow([passed, unitTests]), failedTests: ["j1": [test("testRetry")]], flaky: flaky)

        #expect(kind == .allFlaky(testCount: 1))
        #expect(kind.isFlakyOnly)
    }

    @Test func aTestThatIsNotFlakyIsARealFailure() {
        let kind = CIFailurePolicy.kind(of: workflow([unitTests]), failedTests: ["j1": [test("testRetry"), test("testBadge")]], flaky: flaky)

        #expect(kind == .realTests(job: "unit-tests", count: 1))
        #expect(kind.isFlakyOnly == false)
    }

    @Test func aFailedJobWithoutTestsIsABuildFailure() {
        #expect(CIFailurePolicy.kind(of: workflow([build]), failedTests: [:], flaky: flaky) == .noTests(job: "build"))
        #expect(CIFailurePolicy.kind(of: workflow([build]), failedTests: ["j2": []], flaky: flaky) == .noTests(job: "build"))
    }

    @Test func aFailedWorkflowWithoutFailedJobsNamesTheWorkflow() {
        #expect(CIFailurePolicy.kind(of: workflow([]), failedTests: [:], flaky: flaky) == .noTests(job: "build-and-test"))
    }

    @Test func theFirstFailedJobThatIsNotFlakyDecides() {
        let kind = CIFailurePolicy.kind(of: workflow([unitTests, build]), failedTests: ["j1": [test("testRetry")]], flaky: flaky)

        #expect(kind == .noTests(job: "build"))
    }
}
