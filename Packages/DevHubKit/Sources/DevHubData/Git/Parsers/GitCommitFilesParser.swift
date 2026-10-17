import Foundation
import DevHubDomain

enum GitCommitFilesParser {
    static func parse(_ output: String) -> [GitCommitFile] {
        var tokens = output
            .split(separator: "\0", omittingEmptySubsequences: true)
            .map { String($0).trimmingCharacters(in: .newlines) }
            .filter { $0.isEmpty == false }[...]
        var files: [GitCommitFile] = []
        while let status = tokens.popFirst(), let letter = status.first {
            let kind = GitChangeKind(letter: letter)
            if kind == .renamed || kind == .copied {
                guard let original = tokens.popFirst(), let path = tokens.popFirst() else { break }
                files.append(GitCommitFile(path: path, originalPath: original, kind: kind))
            } else {
                guard let path = tokens.popFirst() else { break }
                files.append(GitCommitFile(path: path, originalPath: nil, kind: kind))
            }
        }
        return files
    }
}
