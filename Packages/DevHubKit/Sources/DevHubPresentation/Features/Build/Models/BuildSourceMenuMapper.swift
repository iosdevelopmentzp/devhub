import Foundation
import DevHubDomain
import DevHubUI

enum BuildSourceMenuMapper {

    static func model(source: BuildSourceChoice, label: String, worktrees: [Worktree], projectName: String) -> BuildSourceMenuModel {
        BuildSourceMenuModel(
            label: label,
            icon: icon(for: source),
            hint: "Source: \(label)\nWhat to build: the main checkout, a worktree, or any branch. A branch without a worktree gets one on the next run.",
            mainTitle: "Main checkout · \(worktrees.first(where: \.isMain)?.displayName ?? projectName)",
            worktreesTitle: "Worktrees",
            worktrees: worktrees
                .filter { $0.isMain == false && $0.isMissing == false }
                .map { BuildSourceMenuModel.Item(path: $0.path, title: $0.displayName) },
            otherBranchTitle: "Other Branch…"
        )
    }

    static func icon(for source: BuildSourceChoice) -> String {
        switch source {
        case .main: "house"
        case .worktree: "rectangle.stack"
        case .branch: "arrow.triangle.branch"
        }
    }
}
