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
        let headerEnd = diff.lines.firstIndex { $0.hasPrefix("@@") } ?? 0
        let hunkLines = Array(diff.lines[headerEnd...])
        let lines = zip(hunkLines, DiffLineNumbering.numbers(for: hunkLines)).enumerated().map { offset, pair in
            line(id: offset, text: pair.0, numbers: pair.1)
        }
        return .lines(lines, droppedNote: diff.droppedLines > 0 ? "… \(diff.droppedLines) more lines not shown" : nil)
    }

    static func line(id: Int, text: String, numbers: DiffLineNumbers) -> DiffLineModel {
        let shown = text.isEmpty ? " " : text
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
