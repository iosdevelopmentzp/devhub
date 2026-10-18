import Foundation

package struct GraphQLOperation: Hashable, Sendable {
    package enum Kind: String, Hashable, Sendable {
        case query
        case mutation
        case subscription
    }

    package var name: String?
    package var kind: Kind
    package var variables: String?

    package init(name: String?, kind: Kind, variables: String?) {
        self.name = name
        self.kind = kind
        self.variables = variables
    }
}
