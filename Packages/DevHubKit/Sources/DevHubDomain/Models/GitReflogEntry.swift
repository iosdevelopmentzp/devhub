import Foundation

package struct GitReflogEntry: Identifiable, Hashable, Sendable {
    package var id: Int { index }
    package let index: Int
    package let hash: String
    package let shortHash: String
    package let date: Date?
    package let action: String
    package let message: String

    package init(index: Int, hash: String, shortHash: String, date: Date?, action: String, message: String) {
        self.index = index
        self.hash = hash
        self.shortHash = shortHash
        self.date = date
        self.action = action
        self.message = message
    }

    package var selector: String {
        "HEAD@{\(index)}"
    }
}
