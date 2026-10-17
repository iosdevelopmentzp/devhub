import Foundation
import DevHubDomain

enum GitDiffOutputParser {
    static func parse(_ output: String, maxLines: Int) -> GitDiff {
        let lines = output.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        let isBinary = lines.contains { $0.hasPrefix("Binary files") }
        return GitDiff(lines: Array(lines.prefix(maxLines)), droppedLines: max(lines.count - maxLines, 0), isBinary: isBinary)
    }
}
