import Foundation

package struct CodeHostScope: Hashable, Sendable {
    package var name: String
    package var purpose: String
    package var alternatives: [String]

    package init(name: String, purpose: String, alternatives: [String]) {
        self.name = name
        self.purpose = purpose
        self.alternatives = alternatives
    }

    package func isGranted(by scopes: [String]) -> Bool {
        scopes.contains(name) || alternatives.contains { scopes.contains($0) }
    }
}
