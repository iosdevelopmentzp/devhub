import Foundation

package struct PullRequestNote: Hashable, Sendable {
    package let author: String
    package let body: String
    package let createdAt: Date?

    package init(author: String, body: String, createdAt: Date? = nil) {
        self.author = author
        self.body = body
        self.createdAt = createdAt
    }
}
