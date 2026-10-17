import Foundation
import DevHubDomain

enum GitStatusParser {

    static func parse(_ output: String) -> [GitFileChange] {
        var entries = output.split(separator: "\0", omittingEmptySubsequences: true).map(String.init)[...]
        var changes: [GitFileChange] = []
        while let entry = entries.popFirst() {
            guard entry.count > 3 else { continue }
            let x = entry[entry.startIndex]
            let y = entry[entry.index(after: entry.startIndex)]
            let path = String(entry.dropFirst(3))
            let original = x == "R" || x == "C" ? entries.popFirst() : nil
            if x == "?" {
                changes.append(GitFileChange(path: path, originalPath: nil, area: .untracked, kind: .untracked))
            } else if x == "U" || y == "U" || (x == "A" && y == "A") || (x == "D" && y == "D") {
                changes.append(GitFileChange(path: path, originalPath: nil, area: .conflicted, kind: .conflicted))
            } else {
                if x != " " {
                    changes.append(GitFileChange(path: path, originalPath: original, area: .staged, kind: GitChangeKind(letter: x)))
                }
                if y != " " {
                    changes.append(GitFileChange(path: path, originalPath: nil, area: .unstaged, kind: GitChangeKind(letter: y)))
                }
            }
        }
        return changes
    }
}
