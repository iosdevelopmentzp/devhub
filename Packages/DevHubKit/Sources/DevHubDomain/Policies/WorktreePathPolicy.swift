import Foundation

package enum WorktreePathPolicy {
    package static func path(forBranch branch: String, root: String, folder: String?) -> String {
        let name = branch.replacingOccurrences(of: "/", with: "-")
        guard let folder else {
            let parent = (root as NSString).deletingLastPathComponent
            return (parent as NSString).appendingPathComponent("\((root as NSString).lastPathComponent)-\(name)")
        }
        let base = folder.hasPrefix("/") ? folder : (root as NSString).appendingPathComponent(folder)
        return ((base as NSString).appendingPathComponent(name) as NSString).standardizingPath
    }
}
