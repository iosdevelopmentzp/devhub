import Foundation

package struct ReviewWait: Codable, Hashable, Sendable {
    package let iid: Int
    package let since: Date
    package var isReminded: Bool

    package init(iid: Int, since: Date, isReminded: Bool) {
        self.iid = iid
        self.since = since
        self.isReminded = isReminded
    }
}
