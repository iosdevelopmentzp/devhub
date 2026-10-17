import Foundation

package struct PullRequestNote: Hashable, Sendable {
    package let author: String
    package let body: String

    package init(author: String, body: String) {
        self.author = author
        self.body = body
    }
}
