import Foundation
import DevHubDomain

extension MockData {
    package static let ciWorkflowID = "11111111-2222-3333-4444-555555555555"
    package static let ciRunID = "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"

    package static let ciToolState = CIToolState(isInstalled: true, version: "1.13.0", isLoggedIn: true)

    package static let ciWorkflow = CIWorkflow(
        id: ciWorkflowID,
        name: "build-and-test",
        status: .failed,
        runID: ciRunID,
        jobs: [
            CIJob(id: "job-build", name: "build", status: .success, isApproval: false),
            CIJob(id: "job-unit-tests", name: "unit-tests", status: .failed, isApproval: false),
            CIJob(id: "job-ui-tests", name: "ui-tests", status: .skipped, isApproval: false),
            CIJob(id: "job-approve-release", name: "approve-release", status: .manual, isApproval: true),
        ]
    )

    package static let ciRuns: [CIRun] = [
        CIRun(id: ciRunID, status: .failed, branch: "feature/ABC-123-short-title", revision: "aaa111bbb222", createdAt: ago(minutes: 40)),
        CIRun(id: "ffffffff-1111-2222-3333-444444444444", status: .success, branch: "main", revision: "ccc333ddd444", createdAt: ago(hours: 5)),
    ]

    package static let ciFailedTests: [CITestResult] = [
        CITestResult(className: "LoginViewModelTests", name: "testRetryAfterTimeout", result: "failure", runTime: 2.4, message: "XCTAssertEqual failed: (\"retrying\") is not equal to (\"idle\")"),
        CITestResult(className: "ProfileBadgeTests", name: "testBadgeCount", result: "failure", runTime: 0.1, message: "XCTAssertEqual failed: (3) is not equal to (2)"),
    ]

    package static let ciPreviousWorkflow = CIWorkflow(
        id: "99999999-8888-7777-6666-555555555555",
        name: "build-and-test",
        status: .failed,
        runID: ciRunID,
        jobs: [
            CIJob(id: "job-build-1", name: "build", status: .success, isApproval: false),
            CIJob(id: "job-unit-tests-1", name: "unit-tests", status: .failed, isApproval: false),
        ]
    )

    package static let ciPreviousFailedTests: [String: [CITestResult]] = ["job-unit-tests-1": ciFailedTests]

    package static let ciFlakyTests: [CIFlakyTest] = [
        CIFlakyTest(className: "LoginViewModelTests", name: "testRetryAfterTimeout", jobName: "unit-tests", workflowName: "build-and-test", timesFlaked: 7),
    ]

    package static let ciJobLog = """
    == Spin up environment
    Build-agent version 1.0.0

    == Checkout code
    Cloning git repository

    == Run tests
    Test Suite 'All tests' started
    Test Case 'LoginViewModelTests.testRetryAfterTimeout' failed (2.4 seconds)
    Executed 412 tests, with 2 failures
    == Run tests (exit 65)
    """
}
