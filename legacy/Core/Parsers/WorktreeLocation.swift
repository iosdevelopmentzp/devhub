import Foundation

nonisolated enum WorktreeLocation {
    static func path(repository: String, folder: String?, branch: String) -> String {
        let name = branch.replacingOccurrences(of: "/", with: "-")
        let base = repository.hasSuffix("/") ? String(repository.dropLast()) : repository
        guard let folder, folder.isEmpty == false else {
            return base + "-" + name
        }
        let container = folder.hasPrefix("/") ? folder : base + "/" + folder
        return container + "/" + name
    }
}
