import Foundation

package enum DiffLineNumbering {

    package static func numbers(for lines: [String]) -> [DiffLineNumbers] {
        var oldLine = 0
        var newLine = 0
        var inHunk = false
        return lines.map { text in
            if text.hasPrefix("@@") {
                guard let start = hunkStart(text) else { return .none }
                oldLine = start.old
                newLine = start.new
                inHunk = true
                return .none
            }
            guard inHunk, text.hasPrefix("\\") == false else { return .none }
            if text.hasPrefix("-") {
                defer { oldLine += 1 }
                return DiffLineNumbers(old: oldLine, new: nil)
            }
            if text.hasPrefix("+") {
                defer { newLine += 1 }
                return DiffLineNumbers(old: nil, new: newLine)
            }
            defer {
                oldLine += 1
                newLine += 1
            }
            return DiffLineNumbers(old: oldLine, new: newLine)
        }
    }

    package static func hunkStart(_ header: String) -> (old: Int, new: Int)? {
        let parts = header.split(separator: " ")
        guard parts.count >= 3,
              let old = start(parts[1], prefix: "-"),
              let new = start(parts[2], prefix: "+") else { return nil }
        return (old, new)
    }

    private static func start(_ part: Substring, prefix: Character) -> Int? {
        guard part.first == prefix else { return nil }
        return Int(part.dropFirst().split(separator: ",").first ?? "")
    }
}
