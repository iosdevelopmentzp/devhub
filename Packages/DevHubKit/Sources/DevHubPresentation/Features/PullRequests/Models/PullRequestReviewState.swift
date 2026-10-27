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

    static let initial = PullRequestReviewState(expandedFiles: [], viewedFiles: [], focus: nil, busyThreads: [], showsThreadsInDiff: true, openDiffThreads: [])
}
