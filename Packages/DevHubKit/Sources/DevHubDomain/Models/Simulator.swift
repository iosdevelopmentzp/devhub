import Foundation

package struct Simulator: Identifiable, Hashable, Sendable {
    package enum State: Hashable, Sendable {
        case booted
        case shutdown
        case booting
        case shuttingDown
    }

    package enum Kind: Hashable, Sendable {
        case phone
        case pad
    }

    package let id: String
    package var name: String
    package var kind: Kind
    package var state: State
    package var isFavorite: Bool
    package var isPhysical = false
    package var runtime: String? = nil

    package init(id: String, name: String, kind: Kind, state: State, isFavorite: Bool, isPhysical: Bool = false, runtime: String? = nil) {
        self.id = id
        self.name = name
        self.kind = kind
        self.state = state
        self.isFavorite = isFavorite
        self.isPhysical = isPhysical
        self.runtime = runtime
    }
}
