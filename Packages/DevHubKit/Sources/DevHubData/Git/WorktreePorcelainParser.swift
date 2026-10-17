import Foundation
import DevHubDomain

enum WorktreePorcelainParser {
    struct Entry: Sendable {
        var path: String
        var head = ""
        var branch: String?
        var isLocked = false
        var isPrunable = false
    }

    static func parse(_ output: String) -> [Entry] {
        var entries: [Entry] = []
        var current: Entry?
        for line in output.split(separator: "\n", omittingEmptySubsequences: false).map(String.init) {
            if line.hasPrefix("worktree ") {
                if let current { entries.append(current) }
                current = Entry(path: String(line.dropFirst("worktree ".count)))
            } else if line.hasPrefix("HEAD ") {
                current?.head = String(line.dropFirst("HEAD ".count))
            } else if line.hasPrefix("branch ") {
                current?.branch = String(line.dropFirst("branch ".count)).replacingOccurrences(of: "refs/heads/", with: "")
            } else if line == "locked" || line.hasPrefix("locked ") {
                current?.isLocked = true
            } else if line == "prunable" || line.hasPrefix("prunable ") {
                current?.isPrunable = true
            }
        }
        if let current { entries.append(current) }
        return entries
    }
}
