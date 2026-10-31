import Foundation
import DevHubUI

struct CIHistoryRowModel: Identifiable, Equatable {
    struct FailedJob: Identifiable, Equatable {
        let id: String
        var title: String
        var tests: [PipelineJobRowModel.FailedTest]
    }

    let id: String
    var title: String
    var statusTag: TagModel
    var timeText: String?
    var summaryText: String
    var failedJobs: [FailedJob]
    var toggleHint: String

    static let preview = CIHistoryRowModel(
        id: "22222222-3333-4444-5555-666666666666",
        title: "build-and-test",
        statusTag: TagModel("failed", tint: .red, systemImage: "xmark.circle.fill", hint: "The state of this workflow when DevHub last read it"),
        timeText: "2 hr. ago",
        summaryText: "1 failed job · 2 failed tests",
        failedJobs: [FailedJob(id: "job-unit-tests", title: "unit-tests", tests: PipelineJobRowModel.previewCircleCI.failedTests)],
        toggleHint: "Show the failed jobs and tests of this run"
    )
}
