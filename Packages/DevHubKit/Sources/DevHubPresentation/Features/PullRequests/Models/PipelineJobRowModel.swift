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
        isBusy: false
,
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
        durationText: nil,
        allowedToFailText: nil,
        failureText: nil,
        url: nil,
        canShowLog: true,
        isLogOpen: false,
        log: nil,
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
        ]
,
        detailsTitle: "2 failed tests",
        detailsHint: "Hide the failed tests",
        isDetailsOpen: true
    )
}
