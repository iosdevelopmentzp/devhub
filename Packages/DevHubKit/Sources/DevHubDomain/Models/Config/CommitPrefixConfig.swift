import Foundation

package struct CommitPrefixConfig: Codable, Hashable, Sendable {
    package var pattern: String? = nil
    package var format: String? = nil

    package init(
        pattern: String? = nil,
        format: String? = nil
    ) {
        self.pattern = pattern
        self.format = format
    }
}
