import Foundation

package struct MockRoute: Hashable, Sendable {
    package var path: String
    package var upstream: URL

    package init(path: String, upstream: URL) {
        self.path = path
        self.upstream = upstream
    }
}
