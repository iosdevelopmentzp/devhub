import Foundation

package struct PullRequestSettings: Hashable, Sendable {
    package var targets: [String]?
    package var template: String?
    package var staleDays: Int
    package var hiddenFiles: [String]
    package var isDraft: Bool
    package var deleteSourceBranch: Bool
    package var squash: Bool
    package var reviewCommand: String

    package init(targets: [String]?, template: String?, staleDays: Int, hiddenFiles: [String], isDraft: Bool, deleteSourceBranch: Bool, squash: Bool, reviewCommand: String) {
        self.targets = targets
        self.template = template
        self.staleDays = staleDays
        self.hiddenFiles = hiddenFiles
        self.isDraft = isDraft
        self.deleteSourceBranch = deleteSourceBranch
        self.squash = squash
        self.reviewCommand = reviewCommand
    }
}
