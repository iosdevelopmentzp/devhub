import Foundation
import DevHubDomain
import DevHubUI

enum BuildSourceMenuMapper {

    static func model(worktrees: [Worktree], projectName: String) -> BuildSourceMenuModel {
        BuildSourceMenuModel(
            mainTitle: "Main checkout · \(worktrees.first(where: \.isMain)?.displayName ?? projectName)",
            worktreesTitle: "Worktrees",
            worktrees: worktrees
                .filter { $0.isMain == false && $0.isMissing == false }
                .map { BuildSourceMenuModel.Item(path: $0.path, title: $0.displayName) },
            otherBranchTitle: "Other Branch…"
        )
    }
}
