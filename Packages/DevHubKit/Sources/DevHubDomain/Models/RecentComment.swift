import Foundation

package struct RecentComment: Hashable, Sendable {
    package let id: String
    package let author: String

    package init(id: String, author: String) {
        self.id = id
        self.author = author
    }
}
