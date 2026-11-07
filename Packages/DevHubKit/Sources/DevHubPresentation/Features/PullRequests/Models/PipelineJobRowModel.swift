import Foundation
import DevHubUI

struct PipelineJobRowModel: Identifiable, Equatable {
    struct FailedTest: Identifiable, Equatable {
        let id: String
        var title: String
        var message: String?
        var flakyText: String?
        var isMessageOpen = false
    }

    struct Step: Identifiable, Equatable {
        let id: Int
        var title: String
        var icon: String
        var tint: Tint
        var durationText: String?
        var exitText: String?
    }

    struct ArtifactRow: Identifiable, Equatable {
        let id: String
        var path: String
        var url: URL?
    }

    enum Artifacts: Equatable {
        case loading
        case loaded([ArtifactRow])
        case failure(String)
    }

    let id: String
    var jobID: String?
    var title: String
    var icon: String
    var tint: Tint
    var statusText: String
    var durationText: String?
    var allowedToFailText: String?
    var failureText: String?
    var url: URL?
    var canShowLog: Bool
    var isLogOpen: Bool
    var log: JobLogState?
    var logHint = "Show the end of the log"
    var canRetry: Bool
    var retryHint: String
    var isBusy: Bool
    var canApprove = false
    var approveHint = ""
    var noteText: String?
    var flakyTag: TagModel?
    var failedTests: [FailedTest] = []
    var detailsTitle: String? = nil
    var detailsHint = ""
    var isDetailsOpen = false
    var steps: [Step] = []
    var canShowArtifacts = false
    var isArtifactsOpen = false
    var artifacts: Artifacts? = nil
    var downloadTitle: String? = nil
    var downloadFolder: String? = nil
    var downloadFailure: String? = nil

    static let preview = PipelineJobRowModel(
        id: "71",
        jobID: "71",
        title: "unit-tests",
        icon: "xmark.circle.fill",
        tint: .red,
        statusText: "failed",
        durationText: "2 m 10 s",
        allowedToFailText: nil,
        failureText: "The script exited with code 65",
        url: URL(string: "https://gitlab.com/example/app/-/jobs/71"),
        canShowLog: true,
        isLogOpen: true,
        log: .loaded("LoginTests.testWrongPassword failed: expected 401\n** TEST FAILED **"),
        canRetry: true,
        retryHint: "Run this job again",
        isBusy: false,
        detailsTitle: "reason",
        detailsHint: "Hide the failure message",
        isDetailsOpen: true
    )

    static let previewCircleCI = PipelineJobRowModel(
        id: "job-unit-tests",
        jobID: "job-unit-tests",
        title: "unit-tests",
        icon: "xmark.circle.fill",
        tint: .red,
        statusText: "failed",
        durationText: "8 m 25 s",
        allowedToFailText: nil,
        failureText: "Run tests failed (exit 65)",
        url: URL(string: "https://app.circleci.example.com/pipelines/github/example/app/42/workflows/11111111-2222-3333-4444-555555555555/jobs/102"),
        canShowLog: true,
        isLogOpen: false,
        log: nil,
        logHint: "Show the log: the failed steps first, then the others",
        canRetry: true,
        retryHint: "Run the failed jobs of build-and-test again",
        isBusy: false,
        canApprove: false,
        approveHint: "",
        noteText: nil,
        flakyTag: TagModel("1 of 2 flaky", tint: .orange, systemImage: "shuffle", hint: "1 of 2 failed tests is flaky: it passed on a re-run before (CircleCI Insights)"),
        failedTests: [
            FailedTest(id: "job-unit-tests/LoginViewModelTests.testRetryAfterTimeout", title: "LoginViewModelTests.testRetryAfterTimeout", message: "XCTAssertEqual failed: (\"retrying\") is not equal to (\"idle\")", flakyText: "flaky · flaked 7 times", isMessageOpen: true),
            FailedTest(id: "job-unit-tests/ProfileBadgeTests.testBadgeCount", title: "ProfileBadgeTests.testBadgeCount", message: "XCTAssertEqual failed: (3) is not equal to (2)", flakyText: nil),
        ],
        detailsTitle: "2 failed tests",
        detailsHint: "Hide the failed tests",
        isDetailsOpen: true,
        steps: [
            Step(id: 0, title: "Spin up environment", icon: "checkmark.circle.fill", tint: .green, durationText: "3 s", exitText: nil),
            Step(id: 1, title: "Checkout code", icon: "checkmark.circle.fill", tint: .green, durationText: "8 s", exitText: nil),
            Step(id: 2, title: "Run tests", icon: "xmark.circle.fill", tint: .red, durationText: "7 m 32 s", exitText: "exit 65"),
        ],
        canShowArtifacts: true,
        isArtifactsOpen: true,
        artifacts: .loaded([
            ArtifactRow(id: "test-results/junit.xml", path: "test-results/junit.xml", url: URL(string: "https://app.circleci.example.com/artifacts/0/test-results/junit.xml")),
            ArtifactRow(id: "screenshots/LoginTests.png", path: "screenshots/LoginTests.png", url: nil),
        ]),
        downloadTitle: "Download All"
    )
}
