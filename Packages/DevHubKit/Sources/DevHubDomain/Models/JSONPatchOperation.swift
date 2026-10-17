import Foundation

package struct JSONPatchOperation: Hashable, Sendable {
    package var keyPath: String
    package var value: String?

    package init(keyPath: String, value: String?) {
        self.keyPath = keyPath
        self.value = value
    }

    package var isRemove: Bool {
        value == nil
    }
}
