import Foundation

package struct DiffLineNumbers: Hashable, Sendable {
    package let old: Int?
    package let new: Int?

    package init(old: Int?, new: Int?) {
        self.old = old
        self.new = new
    }

    package static let none = DiffLineNumbers(old: nil, new: nil)
}
