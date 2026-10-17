import Foundation

package struct MergeRequestFileDiff: Identifiable, Hashable, Sendable {
    package enum Kind: Hashable, Sendable {
        case added
        case deleted
        case renamed
        case modified
    }

    package var id: String { path }
    package let oldPath: String
    package let path: String
    package let kind: Kind
    package let additions: Int
    package let deletions: Int
    package let diff: GitDiff
    package let isTooLarge: Bool

    package init(oldPath: String, path: String, kind: Kind, additions: Int, deletions: Int, diff: GitDiff, isTooLarge: Bool) {
        self.oldPath = oldPath
        self.path = path
        self.kind = kind
        self.additions = additions
        self.deletions = deletions
        self.diff = diff
        self.isTooLarge = isTooLarge
    }
}
