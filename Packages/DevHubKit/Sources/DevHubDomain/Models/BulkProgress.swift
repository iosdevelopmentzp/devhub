import Foundation

package struct BulkProgress: Hashable, Sendable {
    package var done: Int
    package var total: Int
    package var current: String

    package init(done: Int, total: Int, current: String) {
        self.done = done
        self.total = total
        self.current = current
    }
}
