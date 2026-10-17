import Foundation
import DevHubDomain
import DevHubUI

enum ProjectCardMapper {

    static func model(for project: Project, main: Worktree?, mainCheckoutPath: String) -> ProjectCardModel {
        let branch = main?.displayName ?? "—"
        return ProjectCardModel(
            name: project.name,
            path: project.path,
            mainCheckoutPath: mainCheckoutPath,
            branchTag: TagModel(branch, tint: .blue, systemImage: "arrow.triangle.branch"),
            statusTags: statusTags(for: main)
        )
    }

    private static func statusTags(for main: Worktree?) -> [TagModel] {
        let changedFiles = main?.changedFiles ?? 0
        let ahead = main?.ahead ?? 0
        let behind = main?.behind ?? 0
        var tags: [TagModel] = []
        if changedFiles == 0 {
            tags.append(TagModel("clean", tint: .green, systemImage: "checkmark"))
        } else {
            tags.append(TagModel("\(changedFiles) changed", tint: .orange, systemImage: "pencil"))
        }
        if ahead > 0 {
            tags.append(TagModel(SyncText.ahead(ahead)))
        }
        if behind > 0 {
            tags.append(TagModel(SyncText.behind(behind), tint: .red))
        }
        return tags
    }
}
