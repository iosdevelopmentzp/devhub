import Foundation

package struct NewWorktree: Sendable {
    package var path: String
    package var branch: String

    package init(path: String, branch: String) {
        self.path = path
        self.branch = branch
    }
}
