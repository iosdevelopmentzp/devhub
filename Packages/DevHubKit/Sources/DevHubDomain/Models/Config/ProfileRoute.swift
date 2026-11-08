import Foundation

package struct ProfileRoute: Codable, Hashable, Sendable {
    package var path: String
    package var upstream: String

    package init(path: String, upstream: String) {
        self.path = path
        self.upstream = upstream
    }
}
