import Foundation

package enum WorktreePathPolicy {
    package static let projectFolder = ".worktrees"
    package static let ignorePattern = ".worktrees/"
    package static let excludeHeader = "# Worktrees created by DevHub"

    package static func path(forBranch branch: String, root: String, folder: String?) -> String {
        let name = branch.replacingOccurrences(of: "/", with: "-")
        guard let folder else {
            let parent = (root as NSString).deletingLastPathComponent
            return (parent as NSString).appendingPathComponent("\((root as NSString).lastPathComponent)-\(name)")
        }
        let base = folder.hasPrefix("/") ? folder : (root as NSString).appendingPathComponent(folder)
        return ((base as NSString).appendingPathComponent(name) as NSString).standardizingPath
    }

    package static func folder(for location: WorktreeLocation) -> String? {
        switch location {
        case .configured(let folder): folder
        case .insideProject: projectFolder
        case .nextToProject: nil
        }
    }

    package static func exclude(addingProjectFolderTo text: String) -> String? {
        let patterns: Set<String> = [projectFolder, ignorePattern, "/" + projectFolder, "/" + ignorePattern]
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map { String($0).trimmed }
        guard lines.contains(where: patterns.contains) == false else { return nil }
        let separator = text.isEmpty || text.hasSuffix("\n") ? "" : "\n"
        return text + separator + excludeHeader + "\n" + ignorePattern + "\n"
    }
}
