import Foundation

nonisolated struct ListedWorktree: Hashable, Sendable {
    var path: String
    var head: String
    var branch: String?
    var isLocked: Bool
    var isPrunable: Bool
}

nonisolated enum GitWorktreeParser {
    static func parse(_ output: String) -> [ListedWorktree] {
        var result: [ListedWorktree] = []
        var current: ListedWorktree?
        for line in output.split(separator: "\n", omittingEmptySubsequences: false).map(String.init) {
            if line.hasPrefix("worktree ") {
                if let current { result.append(current) }
                current = ListedWorktree(path: String(line.dropFirst("worktree ".count)), head: "", branch: nil, isLocked: false, isPrunable: false)
            } else if line.hasPrefix("HEAD ") {
                current?.head = String(line.dropFirst("HEAD ".count))
            } else if line.hasPrefix("branch ") {
                let reference = String(line.dropFirst("branch ".count))
                current?.branch = reference.hasPrefix("refs/heads/") ? String(reference.dropFirst("refs/heads/".count)) : reference
            } else if line == "locked" || line.hasPrefix("locked ") {
                current?.isLocked = true
            } else if line == "prunable" || line.hasPrefix("prunable ") {
                current?.isPrunable = true
            }
        }
        if let current { result.append(current) }
        return result
    }
}
