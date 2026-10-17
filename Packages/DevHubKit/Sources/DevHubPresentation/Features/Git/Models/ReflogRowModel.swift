import Foundation
import DevHubDomain
import DevHubUI

struct ReflogRowModel: Identifiable, Equatable {
    let id: GitReflogEntry.ID
    var selector: String
    var hash: String
    var shortHash: String
    var actionTag: TagModel
    var message: String
    var dateText: String?
    var files: CommitRowModel.Files?

    var isExpanded: Bool {
        files != nil
    }

    static let preview = ReflogRowModel(
        id: 1,
        selector: "HEAD@{1}",
        hash: "a1b2c3d4e5f6",
        shortHash: "a1b2c3d",
        actionTag: TagModel("checkout", tint: .blue),
        message: "moving from dev to ABC-2324-paidCall",
        dateText: "1 hr. ago",
        files: nil
    )
}
