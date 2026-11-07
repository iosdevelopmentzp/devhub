import Foundation

package struct FileGroupConfig: Codable, Hashable, Sendable {
    package var name: String? = nil
    package var patterns: [String]? = nil
    package var hidden: Bool? = nil

    package init(name: String? = nil, patterns: [String]? = nil, hidden: Bool? = nil) {
        self.name = name
        self.patterns = patterns
        self.hidden = hidden
    }
}
