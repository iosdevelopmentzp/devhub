import Foundation
import DevHubDomain
import DevHubUI

enum DiffMapper {

    static func model(for diff: GitDiff?) -> DiffModel {
        guard let diff else { return .loading }
        if diff.isBinary {
            return .note("Binary file, no text diff")
        }
        if diff.lines.allSatisfy(\.isEmpty) {
            return .note("No text changes. Only the file mode or an empty file changed.")
        }
        let hunkLines = hunkLines(of: diff)
        var lines = zip(hunkLines, DiffLineNumbering.numbers(for: hunkLines)).enumerated().map { offset, pair in
            line(id: offset, text: pair.0, numbers: pair.1)
        }
        for pair in DiffLineEmphasis.pairs(in: hunkLines) {
            guard let ranges = DiffLineEmphasis.ranges(removed: String(hunkLines[pair.removed].dropFirst()), added: String(hunkLines[pair.added].dropFirst())) else { continue }
            lines[pair.removed].emphasis = ranges.removed.map { ($0.lowerBound + 1)..<($0.upperBound + 1) }
            lines[pair.added].emphasis = ranges.added.map { ($0.lowerBound + 1)..<($0.upperBound + 1) }
        }
        return .lines(lines, droppedNote: diff.droppedLines > 0 ? "… \(diff.droppedLines) more lines not shown" : nil)
    }

    static func hunkLines(of diff: GitDiff) -> [String] {
        let headerEnd = diff.lines.firstIndex { $0.hasPrefix("@@") } ?? 0
        return Array(diff.lines[headerEnd...])
    }

    static func shownText(_ text: String) -> String {
        text.isEmpty ? " " : text
    }

    static func line(id: Int, text: String, numbers: DiffLineNumbers) -> DiffLineModel {
        let shown = shownText(text)
        if text.hasPrefix("@@") {
            return DiffLineModel(id: id, text: shown, tint: .blue, foregroundOpacity: 1, backgroundOpacity: 0.06, oldNumber: nil, newNumber: nil)
        }
        if text.hasPrefix("+") {
            return DiffLineModel(id: id, text: shown, tint: .green, foregroundOpacity: 0.9, backgroundOpacity: 0.08, oldNumber: nil, newNumber: numbers.new)
        }
        if text.hasPrefix("-") {
            return DiffLineModel(id: id, text: shown, tint: .red, foregroundOpacity: 0.9, backgroundOpacity: 0.08, oldNumber: numbers.old, newNumber: nil)
        }
        return DiffLineModel(id: id, text: shown, tint: nil, foregroundOpacity: 0.8, backgroundOpacity: 0, oldNumber: numbers.old, newNumber: numbers.new)
    }
}
