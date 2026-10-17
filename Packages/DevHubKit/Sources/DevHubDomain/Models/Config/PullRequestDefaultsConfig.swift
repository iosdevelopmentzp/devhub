import Foundation

package struct PullRequestDefaultsConfig: Codable, Hashable, Sendable {
    package var draft: Bool? = nil
    package var deleteSourceBranch: Bool? = nil
    package var squash: Bool? = nil

    package init(draft: Bool? = nil, deleteSourceBranch: Bool? = nil, squash: Bool? = nil) {
        self.draft = draft
        self.deleteSourceBranch = deleteSourceBranch
        self.squash = squash
    }
}
