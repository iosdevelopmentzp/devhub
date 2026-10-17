import Foundation

package struct NewPullRequest: Hashable, Sendable {
    package var sourceBranch: String
    package var targetBranch: String
    package var title: String
    package var description: String
    package var labels: [String]
    package var isDraft: Bool
    package var removeSourceBranch: Bool
    package var squash: Bool

    package init(
        sourceBranch: String,
        targetBranch: String,
        title: String,
        description: String,
        labels: [String],
        isDraft: Bool,
        removeSourceBranch: Bool,
        squash: Bool
    ) {
        self.sourceBranch = sourceBranch
        self.targetBranch = targetBranch
        self.title = title
        self.description = description
        self.labels = labels
        self.isDraft = isDraft
        self.removeSourceBranch = removeSourceBranch
        self.squash = squash
    }
}
