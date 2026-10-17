import Foundation

package struct HTTPHeader: Hashable, Sendable {
    package var name: String
    package var value: String

    package init(name: String, value: String) {
        self.name = name
        self.value = value
    }
}
