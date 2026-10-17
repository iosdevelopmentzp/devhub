import Foundation

nonisolated enum GitSegment: String, CaseIterable, Hashable, Sendable {
    case local
    case remote
    case history
    case changes
}

nonisolated enum GitConfirmation: Hashable, Sendable {
    case forcePush
    case rebase
    case discard(path: String, group: GitChange.Group)
    case deleteBranch(String)
}

nonisolated struct GitCheckout: Identifiable, Hashable, Sendable {
    let path: String
    let title: String
    let isMain: Bool

    var id: String { path }
}
