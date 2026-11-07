import Foundation
import DevHubDomain

enum GitContainingBranchesParser {
    private static let localPrefix = "refs/heads/"
    private static let remotePrefix = "refs/remotes/"

    static func parse(_ output: String) -> [GitCommitRef] {
        output.split(separator: "\n").compactMap { line in
            let name = line.trimmingCharacters(in: .whitespaces)
            if name.hasPrefix(localPrefix) {
                return GitCommitRef(kind: .localBranch, name: String(name.dropFirst(localPrefix.count)))
            }
            if name.hasPrefix(remotePrefix), name.hasSuffix("/HEAD") == false {
                return GitCommitRef(kind: .remoteBranch, name: String(name.dropFirst(remotePrefix.count)))
            }
            return nil
        }
    }
}
