import Foundation

package struct ProfileStorage: Codable, Hashable, Sendable {
    package var suite: String
    package var key: String

    package init(
        suite: String,
        key: String
    ) {
        self.suite = suite
        self.key = key
    }
}
