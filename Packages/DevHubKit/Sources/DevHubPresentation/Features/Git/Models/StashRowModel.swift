import Foundation
import DevHubDomain
import DevHubUI

struct StashRowModel: Identifiable, Equatable {
    let id: GitStash.ID
    var reference: String
    var message: String
    var branch: String?
    var dateText: String?
    var dropMessage: String
    var areActionsEnabled: Bool

    static let preview = StashRowModel(
        id: 0,
        reference: "stash@{0}",
        message: "half done: the payment form",
        branch: "feature/ABC-2324-paid-call",
        dateText: "2 hr. ago",
        dropMessage: "Drop stash@{0}? Its changes are lost.",
        areActionsEnabled: true
    )
}
