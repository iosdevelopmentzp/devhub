import Foundation
import DevHubDomain
import DevHubUI

struct StashRowModel: Identifiable, Equatable {
    let id: GitStash.ID
    var hash: String
    var reference: String
    var message: String
    var branch: String?
    var dateText: String?
    var dropMessage: String
    var branchPlaceholder: String
    var areActionsEnabled: Bool
    var files: CommitRowModel.Files?

    var isExpanded: Bool {
        files != nil
    }

    static let preview = StashRowModel(
        id: 0,
        hash: "5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a",
        reference: "stash@{0}",
        message: "half done: the payment form",
        branch: "feature/ABC-2324-paid-call",
        dateText: "2 hr. ago",
        dropMessage: "Drop stash@{0}? Its changes are lost.",
        branchPlaceholder: "feature/ABC-2324-paid-call-stash",
        areActionsEnabled: true,
        files: .loaded([.preview])
    )
}
