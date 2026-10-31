import Foundation

package enum DiffContextExpansion {

    package static func expanded(_ diff: GitDiff, fileLines: [String]) -> GitDiff? {
        guard diff.isBinary == false, diff.droppedLines == 0 else { return nil }
        guard let firstHunk = diff.lines.firstIndex(where: { $0.hasPrefix("@@") }) else { return nil }
        var body: [String] = []
        var newCursor = 1
        var oldCount = fileLines.count
        for line in diff.lines[firstHunk...] {
            guard line.hasPrefix("@@") else {
                body.append(line)
                if line.hasPrefix("+") { oldCount -= 1 }
                if line.hasPrefix("-") { oldCount += 1 }
                continue
            }
            guard let start = DiffLineNumbering.hunkStart(line), start.new >= newCursor, start.new - 1 <= fileLines.count else { return nil }
            body += fileLines[(newCursor - 1)..<(start.new - 1)].map { " " + $0 }
            newCursor = start.new + hunkLength(line, side: "+")
        }
        guard newCursor - 1 <= fileLines.count else { return nil }
        body += fileLines[(newCursor - 1)...].map { " " + $0 }
        return GitDiff(lines: ["@@ -1,\(oldCount) +1,\(fileLines.count) @@"] + body, droppedLines: 0, isBinary: false)
    }

    private static func hunkLength(_ header: String, side: Character) -> Int {
        let parts = header.split(separator: " ")
        guard let part = parts.first(where: { $0.first == side && $0.dropFirst().first?.isNumber == true }) else { return 0 }
        let fields = part.dropFirst().split(separator: ",")
        guard fields.count == 2 else { return 1 }
        return Int(fields[1]) ?? 0
    }
}
