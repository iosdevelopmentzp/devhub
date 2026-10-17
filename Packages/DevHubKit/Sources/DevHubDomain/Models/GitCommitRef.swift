import Foundation

package struct GitCommitRef: Hashable, Sendable {
    package enum Kind: Hashable, Sendable {
        case head
        case localBranch
        case remoteBranch
        case tag
    }

    package let kind: Kind
    package let name: String

    package init(kind: Kind, name: String) {
        self.kind = kind
        self.name = name
    }
}
