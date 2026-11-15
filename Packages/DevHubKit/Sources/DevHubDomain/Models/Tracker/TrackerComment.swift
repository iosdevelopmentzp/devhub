import Foundation

package struct TrackerComment: Identifiable, Hashable, Sendable {
    package let id: String
    package var author: String
    package var body: String
    package var createdAt: Date?

    package init(id: String, author: String, body: String, createdAt: Date?) {
        self.id = id
        self.author = author
        self.body = body
        self.createdAt = createdAt
    }
}
