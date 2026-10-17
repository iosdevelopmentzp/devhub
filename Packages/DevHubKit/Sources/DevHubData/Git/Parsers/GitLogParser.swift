import Foundation
import DevHubDomain

enum GitLogParser {
    static let format = ["%H", "%h", "%an", "%ct", "%P", "%D", "%s"].joined(separator: "%x09")

    static func parse(_ log: String, unpushed: Set<String>) -> [GitCommit] {
        log.split(separator: "\n").compactMap { line -> GitCommit? in
            let fields = line.split(separator: "\t", maxSplits: 6, omittingEmptySubsequences: false).map(String.init)
            guard fields.count == 7 else { return nil }
            return GitCommit(
                hash: fields[0],
                shortHash: fields[1],
                author: fields[2],
                date: TimeInterval(fields[3]).map { Date(timeIntervalSince1970: $0) },
                subject: fields[6],
                isPushed: unpushed.contains(fields[0]) == false,
                refs: GitRefDecorationParser.parse(fields[5]),
                isMerge: fields[4].split(separator: " ").count > 1
            )
        }
    }

    static func hashes(_ revList: String) -> Set<String> {
        Set(revList.split(separator: "\n").map(String.init))
    }
}
