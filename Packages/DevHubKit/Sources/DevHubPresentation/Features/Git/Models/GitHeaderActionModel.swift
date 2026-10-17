import Foundation
import DevHubDomain
import DevHubUI

struct GitHeaderActionModel: Identifiable, Equatable {
    let id: GitHeaderAction
    var title: String
    var systemImage: String
    var hint: String
    var priority: Int
    var isDisabled: Bool

    static let preview = GitHeaderActionModel(
        id: .fetch,
        title: "Fetch",
        systemImage: "arrow.down.circle",
        hint: "Download new commits and branches from the remote. git fetch --prune <remote>",
        priority: 3,
        isDisabled: false
    )
}
