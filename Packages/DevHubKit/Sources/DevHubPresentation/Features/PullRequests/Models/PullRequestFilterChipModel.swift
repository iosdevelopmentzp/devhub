import Foundation

struct PullRequestFilterChipModel: Identifiable, Equatable {
    enum Kind: Hashable {
        case targetBranch
        case label
        case onlyConflicts
        case onlyReady
    }

    var id: Kind { kind }
    let kind: Kind
    var title: String
    var systemImage: String
}
