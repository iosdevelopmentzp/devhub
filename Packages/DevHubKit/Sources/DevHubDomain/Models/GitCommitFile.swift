import Foundation

package struct GitCommitFile: Identifiable, Hashable, Sendable {
    package var id: String { path }
    package let path: String
    package let originalPath: String?
    package let kind: GitChangeKind

    package init(path: String, originalPath: String?, kind: GitChangeKind) {
        self.path = path
        self.originalPath = originalPath
        self.kind = kind
    }

    package var fileName: String {
        (path as NSString).lastPathComponent
    }

    package var folder: String {
        (path as NSString).deletingLastPathComponent
    }
}
