import Foundation

package struct GraphQLExchange: Hashable, Sendable {
    package var operations: [GraphQLOperation]
    package var errors: [String]

    package init(operations: [GraphQLOperation], errors: [String]) {
        self.operations = operations
        self.errors = errors
    }

    package var operationNames: [String] {
        operations.compactMap(\.name)
    }

    package var title: String {
        let names = operationNames
        guard names.isEmpty == false else { return "anonymous \(operations.first?.kind.rawValue ?? "query")" }
        return names.joined(separator: ", ")
    }
}
