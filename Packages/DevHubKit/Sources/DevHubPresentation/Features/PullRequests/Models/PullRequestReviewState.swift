import Foundation
import DevHubDomain

struct PullRequestReviewState: Equatable {
    var expandedFiles: Set<PullRequestFileDiff.ID>
    var viewedFiles: Set<PullRequestFileDiff.ID>
    var focus: DiffFocus?
    var busyThreads: Set<PullRequestThread.ID>
    var showsThreadsInDiff: Bool
    var openDiffThreads: Set<PullRequestThread.ID>

    static let initial = PullRequestReviewState(expandedFiles: [], viewedFiles: [], focus: nil, busyThreads: [], showsThreadsInDiff: true, openDiffThreads: [])
}
