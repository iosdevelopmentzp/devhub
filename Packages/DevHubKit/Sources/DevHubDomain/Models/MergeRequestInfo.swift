import Foundation

package struct MergeRequestInfo: Hashable, Sendable {
    package let iid: Int
    package let title: String
    package let state: MergeRequestState
    package let isDraft: Bool
    package let webURL: URL?
    package let author: String
    package let hasConflicts: Bool
    package let detailedStatus: MergeDetail?
    package let targetBranch: String

    package init(
        iid: Int,
        title: String,
        state: MergeRequestState,
        isDraft: Bool,
        webURL: URL?,
        author: String,
        hasConflicts: Bool,
        detailedStatus: MergeDetail?,
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
