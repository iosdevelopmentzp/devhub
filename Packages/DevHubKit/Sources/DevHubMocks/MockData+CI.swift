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
        CIRun(id: ciRunID, status: .failed, branch: "feature/ABC-123-short-title", revision: "aaa111bbb222", subject: "ABC-123: Retry the login after a timeout", createdAt: ago(minutes: 40)),
        CIRun(id: "ffffffff-1111-2222-3333-444444444444", status: .success, branch: "main", revision: "ccc333ddd444", subject: "Merge pull request #1840", createdAt: ago(hours: 5)),
    ]

    package static let ciRunWorkflows: [CIWorkflow] = [
        CIWorkflow(id: ciWorkflowID, name: "build-and-test", status: .failed, runID: ciRunID, jobs: []),
        CIWorkflow(id: "77777777-8888-9999-aaaa-bbbbbbbbbbbb", name: "nightly", status: .success, runID: ciRunID, jobs: []),
    ]

    package static let ciWorkflowDetails = CIWorkflowDetails(
        id: ciWorkflowID,
        pipelineNumber: 42,
        projectSlug: "gh/example/app",
        createdAt: ago(minutes: 40),
        stoppedAt: ago(minutes: 28),
        jobs: [
            CIJobDetails(id: "job-build", number: 101, startedAt: ago(minutes: 40), stoppedAt: ago(minutes: 36), approvalRequestID: nil),
            CIJobDetails(id: "job-unit-tests", number: 102, startedAt: ago(minutes: 36), stoppedAt: ago(minutes: 28), approvalRequestID: nil),
            CIJobDetails(id: "job-ui-tests", number: 103, startedAt: nil, stoppedAt: nil, approvalRequestID: nil),
            CIJobDetails(id: "job-approve-release", number: 104, startedAt: nil, stoppedAt: nil, approvalRequestID: "approval-1"),
        ]
    )

    package static let ciJobSteps: [CIJobStep] = [
        CIJobStep(index: 0, name: "Spin up environment", status: .success, duration: 3, exitCode: 0),
        CIJobStep(index: 1, name: "Checkout code", status: .success, duration: 8, exitCode: 0),
        CIJobStep(index: 2, name: "Run tests", status: .failed, duration: 452, exitCode: 65),
        CIJobStep(index: 3, name: "Upload test results", status: .success, duration: 2, exitCode: 0),
    ]

    package static let ciArtifacts: [CIArtifact] = [
        CIArtifact(path: "test-results/junit.xml", url: URL(string: "https://app.circleci.example.com/artifacts/0/test-results/junit.xml")),
        CIArtifact(path: "screenshots/LoginTests-testRetryAfterTimeout.png", url: URL(string: "https://app.circleci.example.com/artifacts/0/screenshots/LoginTests-testRetryAfterTimeout.png")),
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
