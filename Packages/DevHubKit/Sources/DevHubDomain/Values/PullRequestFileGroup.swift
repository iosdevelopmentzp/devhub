import Foundation

package struct PullRequestFileGroup: Hashable, Sendable, Identifiable {
    package var id: String { name }
    package let name: String
    package let patterns: [String]
    package let isHiddenByDefault: Bool

    package init(name: String, patterns: [String], isHiddenByDefault: Bool) {
        self.name = name
        self.patterns = patterns
        self.isHiddenByDefault = isHiddenByDefault
    }
}
