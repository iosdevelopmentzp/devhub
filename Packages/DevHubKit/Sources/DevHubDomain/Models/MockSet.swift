import Foundation

package struct MockSet: Identifiable, Hashable, Sendable {
    package let id: UUID
    package var name: String
    package var rules: [MockRule]

    package init(id: UUID, name: String, rules: [MockRule]) {
        self.id = id
        self.name = name
        self.rules = rules
    }
}
