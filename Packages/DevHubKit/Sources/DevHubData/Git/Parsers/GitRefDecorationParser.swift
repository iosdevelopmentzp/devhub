import Foundation
import DevHubDomain

enum GitRefDecorationParser {
    private static let localPrefix = "refs/heads/"
    private static let remotePrefix = "refs/remotes/"
    private static let tagPrefix = "tag: refs/tags/"
    private static let headPointer = "HEAD -> "

    static func parse(_ decoration: String) -> [GitCommitRef] {
        decoration
            .components(separatedBy: ", ")
            .flatMap(refs(in:))
    }

    private static func refs(in item: String) -> [GitCommitRef] {
        if item == "HEAD" {
            return [GitCommitRef(kind: .head, name: "HEAD")]
        }
        if item.hasPrefix(headPointer) {
            return [GitCommitRef(kind: .head, name: "HEAD")] + refs(in: String(item.dropFirst(headPointer.count)))
        }
        if item.hasPrefix(tagPrefix) {
            return [GitCommitRef(kind: .tag, name: String(item.dropFirst(tagPrefix.count)))]
        }
        if item.hasPrefix(localPrefix) {
            return [GitCommitRef(kind: .localBranch, name: String(item.dropFirst(localPrefix.count)))]
        }
        if item.hasPrefix(remotePrefix), item.hasSuffix("/HEAD") == false {
            return [GitCommitRef(kind: .remoteBranch, name: String(item.dropFirst(remotePrefix.count)))]
        }
        return []
    }
}
