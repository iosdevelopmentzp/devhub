import Foundation
import DevHubDomain
import DevHubUI

struct BuildSourceMenuModel: Equatable {
    struct Item: Identifiable, Equatable {
        var id: String { path }
        var path: String
        var title: String
    }

    var mainTitle: String
    var worktreesTitle: String
    var worktrees: [Item]
    var otherBranchTitle: String

    static let preview = BuildSourceMenuModel(
        mainTitle: "Main checkout · ExampleApp",
        worktreesTitle: "Worktrees",
        worktrees: [Item(path:"/Users/me/ExampleApp/.worktrees/login-flow", title: "feature/login-flow")],
        otherBranchTitle: "Other Branch…"
    )
}
