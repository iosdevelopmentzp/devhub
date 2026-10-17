import Foundation

package struct GitStash: Identifiable, Hashable, Sendable {
    package var id: Int { index }
    package let index: Int
    package let branch: String?
    package let message: String
    package let date: Date?

    package init(index: Int, branch: String?, message: String, date: Date?) {
        self.index = index
        self.branch = branch
        self.message = message
        self.date = date
    }
}
