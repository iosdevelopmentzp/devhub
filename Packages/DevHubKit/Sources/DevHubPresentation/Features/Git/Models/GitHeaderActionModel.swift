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
        hint: "Download new commits and branches from origin. git fetch --prune origin",
        priority: 3,
        isDisabled: false
    )
}
