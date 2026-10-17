import Foundation

package struct MockPatch: Hashable, Sendable {
    package var operations: [JSONPatchOperation]
    package var delay: TimeInterval

    package init(operations: [JSONPatchOperation], delay: TimeInterval) {
        self.operations = operations
        self.delay = delay
    }
}
