import Foundation

package struct DiffStats: Hashable, Sendable {
    package let additions: Int
    package let deletions: Int
    package let fileCount: Int

    package init(additions: Int, deletions: Int, fileCount: Int) {
        self.additions = additions
        self.deletions = deletions
        self.fileCount = fileCount
    }
}
