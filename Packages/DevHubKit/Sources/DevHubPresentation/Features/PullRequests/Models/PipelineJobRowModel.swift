import Foundation
import DevHubUI

struct PipelineJobRowModel: Identifiable, Equatable {
    let id: String
    var jobID: String?
    var title: String
    var icon: String
    var tint: Tint
    var statusText: String
    var url: URL?
    var canShowLog: Bool
    var isLogOpen: Bool
    var log: JobLogState?
    var canRetry: Bool
    var retryHint: String
    var isBusy: Bool

    static let preview = PipelineJobRowModel(
        id: "71",
        jobID: "71",
        title: "unit-tests (test)",
        icon: "xmark.octagon.fill",
        tint: .red,
        statusText: "failed",
        url: URL(string: "https://gitlab.com/example/app/-/jobs/71"),
        canShowLog: true,
        isLogOpen: true,
        log: .loaded("LoginTests.testWrongPassword failed: expected 401\n** TEST FAILED **"),
        canRetry: true,
        retryHint: "Run this job again",
        isBusy: false
    )
}
