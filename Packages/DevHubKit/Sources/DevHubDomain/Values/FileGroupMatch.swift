import Foundation

package struct FileGroupMatch: Hashable, Sendable, Identifiable {
    package var id: String { name }
    package let name: String
    package let paths: [String]
    package let isHiddenByDefault: Bool

    package init(name: String, paths: [String], isHiddenByDefault: Bool) {
        self.name = name
        self.paths = paths
        self.isHiddenByDefault = isHiddenByDefault
    }
}
