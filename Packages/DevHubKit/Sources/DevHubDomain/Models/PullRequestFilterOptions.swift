import Foundation

package struct PullRequestFilterOptions: Hashable, Sendable {
    package let targetBranches: [String]
    package let labels: [String]
    package let authors: [String]
    package let assignees: [String]
    package let reviewers: [String]

    package init(targetBranches: [String], labels: [String], authors: [String] = [], assignees: [String] = [], reviewers: [String] = []) {
        self.targetBranches = targetBranches
        self.labels = labels
        self.authors = authors
        self.assignees = assignees
        self.reviewers = reviewers
    }
}
