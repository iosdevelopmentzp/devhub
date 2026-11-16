import Foundation

package struct GitHiddenFile: Identifiable, Hashable, Sendable {
    package enum State: Hashable, Sendable {
        case unchanged
        case modified
        case deleted
    }

    package var id: String { path }
    package let path: String
    package let flags: Set<GitHiddenFlag>
    package let state: State

    package init(path: String, flags: Set<GitHiddenFlag>, state: State) {
        self.path = path
        self.flags = flags
        self.state = state
    }

    package var fileName: String {
        (path as NSString).lastPathComponent
    }

    package var folder: String {
        (path as NSString).deletingLastPathComponent
    }

    package var hasChanges: Bool {
        state != .unchanged
    }
}
