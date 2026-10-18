import Foundation

struct BranchCleanupModel: Equatable {
    var title: String
    var names: String
    var showsForceToggle: Bool
    var hint: String

    static let preview = BranchCleanupModel(
        title: "Delete 212 merged branches?",
        names: "feature/a, feature/b, feature/c, fix/d, fix/e and 207 more",
        showsForceToggle: true,
        hint: "Delete every merged branch in this list that is not checked out. dev, main and master stay."
    )
}
