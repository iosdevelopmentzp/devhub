import Foundation
import DevHubUI

struct PipelineJobGroupModel: Identifiable, Equatable {
    let id: String
    var title: String?
    var icon: String
    var tint: Tint
    var statusText: String
    var jobs: [PipelineJobRowModel]
    var workflowID: String?
    var sourceText: String?
    var canRerunFailed = false
    var canRerunAll = false
    var canCancel = false
    var isBusy = false
    var rerunFailedHint = ""
    var rerunAllHint = ""
    var cancelHint = ""

    static let preview = PipelineJobGroupModel(
        id: "test",
        title: "test",
        icon: "xmark.circle.fill",
        tint: .red,
        statusText: "1 failed · 1 running",
        jobs: [.preview]
    )

    static let previewCircleCI = PipelineJobGroupModel(
        id: "circleci:11111111-2222-3333-4444-555555555555",
        title: "build-and-test",
        icon: "xmark.circle.fill",
        tint: .red,
        statusText: "1 failed",
        jobs: [.previewCircleCI],
        workflowID: "11111111-2222-3333-4444-555555555555",
        sourceText: "CircleCI",
        canRerunFailed: true,
        canRerunAll: true,
        canCancel: false,
        isBusy: false,
        rerunFailedHint: "Run the failed jobs of this workflow again (circleci workflow rerun --from-failed)",
        rerunAllHint: "Run the whole workflow again (circleci workflow rerun)",
        cancelHint: "Stop this workflow (circleci workflow cancel)"
    )
}
