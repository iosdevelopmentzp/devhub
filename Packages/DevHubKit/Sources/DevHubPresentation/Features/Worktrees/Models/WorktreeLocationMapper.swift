import Foundation
import DevHubDomain

enum WorktreeLocationMapper {
    static func model(for location: WorktreeLocation, branch: String, remote: String, root: String) -> WorktreeLocationModel {
        let local = BranchName(branch.trimmed, remote: remote).local
        let name = local.isEmpty ? "<branch>" : local
        let path = WorktreePathPolicy.path(forBranch: name, root: root, folder: WorktreePathPolicy.folder(for: location))
        let insideFolder = (root as NSString).appendingPathComponent(WorktreePathPolicy.projectFolder)
        return WorktreeLocationModel(
            path: path.abbreviatingHome,
            hint: hint(for: location),
            canKeepInside: location == .nextToProject,
            keepInsideHint: "Add \(WorktreePathPolicy.ignorePattern) to .git/info/exclude, so git does not list it. New worktrees then go to \(insideFolder.abbreviatingHome). Worktrees you already have stay where they are."
        )
    }

    private static func hint(for location: WorktreeLocation) -> String {
        switch location {
        case .configured(let folder):
            "The folder comes from git.worktrees.folder (\(folder)) in the .devhub config."
        case .insideProject:
            "Inside the project: git ignores \(WorktreePathPolicy.ignorePattern) through .git/info/exclude or .gitignore."
        case .nextToProject:
            "Next to the project folder."
        }
    }
}
