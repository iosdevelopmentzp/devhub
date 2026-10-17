import Foundation

package struct GitFileChange: Identifiable, Hashable, Sendable {
    package enum Area: Int, Hashable, Sendable, CaseIterable {
        case conflicted
        case staged
        case unstaged
        case untracked
    }

    package var id: String { "\(area.rawValue):\(path)" }
    package let path: String
    package let originalPath: String?
    package let area: Area
    package let kind: GitChangeKind

    package init(path: String, originalPath: String?, area: Area, kind: GitChangeKind) {
        self.path = path
        self.originalPath = originalPath
        self.area = area
        self.kind = kind
    }

    package var fileName: String {
        (path as NSString).lastPathComponent
    }

    package var folder: String {
        (path as NSString).deletingLastPathComponent
    }
}
