import Foundation
import DevHubDomain

enum LocalBranchParser {
    static func parse(_ refs: String, merged: Set<String>, visits: [String: Date]) -> [GitBranch] {
        refs.split(separator: "\n").compactMap { line -> GitBranch? in
            let fields = line.split(separator: "\t", maxSplits: 6, omittingEmptySubsequences: false).map(String.init)
            guard fields.count >= 5 else { return nil }
            let tracking = TrackingInfoParser.tracking(upstream: fields[1], track: fields[2])
            return GitBranch(
                name: fields[0],
                upstream: tracking.upstream,
                ahead: tracking.ahead,
                behind: tracking.behind,
                isGone: tracking.isGone,
                isMerged: MergedBranchPolicy.isMerged(
                    branch: fields[0],
                    upstream: tracking.upstream,
                    ahead: tracking.ahead,
                    mergedBranches: merged
                ),
                subject: fields.count > 6 ? fields[6] : "",
                commitDate: TimeInterval(fields[3]).map { Date(timeIntervalSince1970: $0) },
                lastVisited: visits[fields[0]],
                worktreePath: fields[4].isEmpty ? nil : fields[4],
                author: fields.count > 5 && fields[5].isEmpty == false ? fields[5] : nil
            )
        }
        .sorted { lhs, rhs in
            let left = lhs.lastVisited ?? lhs.commitDate ?? .distantPast
            let right = rhs.lastVisited ?? rhs.commitDate ?? .distantPast
            return left > right
        }
    }
}
