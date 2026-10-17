import Foundation
import DevHubDomain

enum GitBranchHeaderParser {
    static func parse(_ status: String, base: String) -> GitSnapshot {
        var snapshot = GitSnapshot(
            branch: nil, head: "", upstream: nil, ahead: 0, behind: 0, changedFiles: 0, stashCount: 0,
            operation: nil, baseBranch: base, aheadOfBase: 0, behindBase: 0, lastFetch: nil, webURL: nil
        )
        for line in status.split(separator: "\n").map(String.init) {
            if line.hasPrefix("# branch.oid ") {
                snapshot.head = String(line.dropFirst("# branch.oid ".count).prefix(9))
            } else if line.hasPrefix("# branch.head ") {
                let name = String(line.dropFirst("# branch.head ".count))
                snapshot.branch = name == "(detached)" ? nil : name
            } else if line.hasPrefix("# branch.upstream ") {
                snapshot.upstream = String(line.dropFirst("# branch.upstream ".count))
            } else if line.hasPrefix("# branch.ab ") {
                let parts = line.dropFirst("# branch.ab ".count).split(separator: " ")
                snapshot.ahead = parts.first.flatMap { Int($0.dropFirst()) } ?? 0
                snapshot.behind = parts.dropFirst().first.flatMap { Int($0.dropFirst()) } ?? 0
            } else if line.hasPrefix("#") == false, line.isEmpty == false {
                snapshot.changedFiles += 1
            }
        }
        return snapshot
    }
}
