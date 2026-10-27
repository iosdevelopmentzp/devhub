import Foundation
import DevHubDomain

struct PullRequestReviewState: Equatable {
    var expandedFiles: Set<PullRequestFileDiff.ID>
    var viewedFiles: Set<PullRequestFileDiff.ID>
    var focus: DiffFocus?
    var busyThreads: Set<ReviewThread.ID>
    var showsThreadsInDiff: Bool
    var openDiffThreads: Set<ReviewThread.ID>
    var commentDraft = ""
    var isCommentBusy = false
    var lineComment: LineCommentDraft?
    var isLineCommentBusy = false
    var jobLogs: [String: JobLogState] = [:]
    var openJobLogs: Set<String> = []
    var busyJobs: Set<String> = []

    static let initial = PullRequestReviewState(expandedFiles: [], viewedFiles: [], focus: nil, busyThreads: [], showsThreadsInDiff: true, openDiffThreads: [])
}
