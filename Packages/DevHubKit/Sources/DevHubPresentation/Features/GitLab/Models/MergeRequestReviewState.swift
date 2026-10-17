import Foundation
import DevHubDomain

struct MergeRequestReviewState: Equatable {
    var expandedFiles: Set<MergeRequestFileDiff.ID>
    var viewedFiles: Set<MergeRequestFileDiff.ID>
    var focus: DiffFocus?
    var busyThreads: Set<MergeRequestThread.ID>
    var showsThreadsInDiff: Bool
    var openDiffThreads: Set<MergeRequestThread.ID>

    static let initial = MergeRequestReviewState(expandedFiles: [], viewedFiles: [], focus: nil, busyThreads: [], showsThreadsInDiff: true, openDiffThreads: [])
}
