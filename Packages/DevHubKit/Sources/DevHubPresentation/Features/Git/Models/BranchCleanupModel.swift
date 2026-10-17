import Foundation

struct BranchCleanupModel: Equatable {
    var title: String
    var names: String
    var showsForceToggle: Bool

    static let preview = BranchCleanupModel(
        title: "Delete 212 merged branches?",
        names: "feature/a, feature/b, feature/c, fix/d, fix/e and 207 more",
        showsForceToggle: true
    )
}
