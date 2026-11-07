import Foundation
import DevHubDomain

enum UpdateCommitParser {
    static let separator: Character = "\u{1F}"

    static func commits(from stdout: String) -> [UpdateCommit] {
        stdout.split(separator: "\n").compactMap { line in
            let parts = line.split(separator: separator, maxSplits: 1, omittingEmptySubsequences: false)
            guard let hash = parts.first, hash.isEmpty == false else { return nil }
            let subject = parts.count > 1 ? String(parts[1]) : ""
            return UpdateCommit(hash: String(hash), subject: subject.trimmed)
        }
    }
}
