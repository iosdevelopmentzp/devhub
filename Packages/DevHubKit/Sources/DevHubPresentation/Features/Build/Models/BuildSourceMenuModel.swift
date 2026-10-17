import Foundation
import DevHubDomain
import DevHubUI

struct BuildSourceMenuModel: Equatable {
    struct Item: Identifiable, Equatable {
        var id: String { path }
        var path: String
        var title: String
    }

    var label: String
    var icon: String
    var hint: String
    var mainTitle: String
    var worktreesTitle: String
    var worktrees: [Item]
    var otherBranchTitle: String

    static let preview = BuildSourceMenuModel(
        label: "feature/login-flow",
        icon: "rectangle.stack",
        hint: "Source: feature/login-flow\nWhat to build: the main checkout, a worktree, or any branch. A branch without a worktree gets one on the next run.",
        mainTitle: "Main checkout · ExampleApp",
        worktreesTitle: "Worktrees",
        worktrees: [Item(path:"/Users/me/ExampleApp/.worktrees/login-flow", title: "feature/login-flow")],
        otherBranchTitle: "Other Branch…"
    )
}
