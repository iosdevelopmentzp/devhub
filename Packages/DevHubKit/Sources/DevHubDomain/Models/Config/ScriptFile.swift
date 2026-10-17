import Foundation

package struct ScriptFile: Hashable, Sendable {
    package var name: String
    package var head: String
    package var isExecutable: Bool

    package init(
        name: String,
        head: String,
        isExecutable: Bool
    ) {
        self.name = name
        self.head = head
        self.isExecutable = isExecutable
    }
}
