import Foundation

package struct MockRule: Identifiable, Hashable, Sendable {
    package let id: UUID
    package var isEnabled: Bool
    package var method: String?
    package var pathPattern: String
    package var query: String?
    package var action: MockAction

    package init(id: UUID, isEnabled: Bool, method: String?, pathPattern: String, query: String?, action: MockAction) {
        self.id = id
        self.isEnabled = isEnabled
        self.method = method
        self.pathPattern = pathPattern
        self.query = query
        self.action = action
    }
}
