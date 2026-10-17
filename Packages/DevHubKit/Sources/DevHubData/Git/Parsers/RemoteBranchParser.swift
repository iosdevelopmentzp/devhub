import Foundation
import DevHubDomain

enum RemoteBranchParser {
    static func parse(_ refs: String, remote: String) -> [RemoteBranch] {
        refs.split(separator: "\n").compactMap { line -> RemoteBranch? in
            let fields = line.split(separator: "\t", maxSplits: 3, omittingEmptySubsequences: false).map(String.init)
            guard fields.count == 4, fields[0] != "\(remote)/HEAD", fields[0] != remote else { return nil }
            return RemoteBranch(name: fields[0], author: fields[2], subject: fields[3], commitDate: TimeInterval(fields[1]).map { Date(timeIntervalSince1970: $0) })
        }
    }
}
