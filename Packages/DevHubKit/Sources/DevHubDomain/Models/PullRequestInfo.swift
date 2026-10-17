import Foundation

package struct PullRequestInfo: Hashable, Sendable {
    package let iid: Int
    package let title: String
    package let state: PullRequestState
    package let isDraft: Bool
    package let webURL: URL?
    package let author: String
    package let hasConflicts: Bool
    package let detailedStatus: MergeReadiness?
    package let targetBranch: String

    package init(
        iid: Int,
        title: String,
        state: PullRequestState,
        isDraft: Bool,
        webURL: URL?,
        author: String,
        hasConflicts: Bool,
        detailedStatus: MergeReadiness?,
        targetBranch: String
    ) {
        self.iid = iid
        self.title = title
        self.state = state
        self.isDraft = isDraft
        self.webURL = webURL
        self.author = author
        self.hasConflicts = hasConflicts
        self.detailedStatus = detailedStatus
        self.targetBranch = targetBranch
    }
}
