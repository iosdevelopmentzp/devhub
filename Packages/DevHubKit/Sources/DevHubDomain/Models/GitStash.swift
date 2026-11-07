import Foundation

package struct GitStash: Identifiable, Hashable, Sendable {
    package var id: Int { index }
    package let index: Int
    package let hash: String
    package let branch: String?
    package let message: String
    package let date: Date?

    package init(index: Int, hash: String, branch: String?, message: String, date: Date?) {
        self.index = index
        self.hash = hash
        self.branch = branch
        self.message = message
        self.date = date
    }

    package var reference: String {
        "stash@{\(index)}"
    }
}
