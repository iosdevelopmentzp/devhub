import Foundation

package enum InboxChangePolicy {

    package static func newItems(from previous: [InboxItem], to current: [InboxItem]) -> [InboxItem] {
        let known = Set(previous.map(\.id))
        return current.filter { known.contains($0.id) == false }
    }
}
