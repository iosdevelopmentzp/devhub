import Foundation
import DevHubDomain

enum DiffFindPolicy {

    static func matches(in diff: GitDiff, path: String, query: String) -> [DiffFindMatch] {
        guard query.isEmpty == false, diff.isBinary == false else { return [] }
        let hunkLines = DiffMapper.hunkLines(of: diff)
        var numbers: [DiffLineNumbers]?
        var matches: [DiffFindMatch] = []
        for (lineID, text) in hunkLines.enumerated() {
            let ranges = ranges(of: query, in: DiffMapper.shownText(text))
            guard ranges.isEmpty == false else { continue }
            let lineNumbers = numbers ?? DiffLineNumbering.numbers(for: hunkLines)
            numbers = lineNumbers
            guard let line = lineNumbers[lineID].new ?? lineNumbers[lineID].old else { continue }
            matches += ranges.map { DiffFindMatch(path: path, lineID: lineID, range: $0, line: line, isOld: lineNumbers[lineID].new == nil) }
        }
        return matches
    }

    static func marked(_ lines: [DiffLineModel], path: String, find: DiffFindState) -> [DiffLineModel] {
        guard find.query.isEmpty == false else { return lines }
        return lines.map { line in
            guard line.oldNumber != nil || line.newNumber != nil else { return line }
            let ranges = ranges(of: find.query, in: line.text)
            guard ranges.isEmpty == false else { return line }
            var marked = line
            marked.findRanges = ranges
            if let current = find.current, current.path == path, current.lineID == line.id, ranges.contains(current.range) {
                marked.currentFindRange = current.range
            }
            return marked
        }
    }

    static func ranges(of query: String, in text: String) -> [Range<Int>] {
        guard query.isEmpty == false else { return [] }
        var ranges: [Range<Int>] = []
        var start = text.startIndex
        while let found = text.range(of: query, options: .caseInsensitive, range: start..<text.endIndex), found.isEmpty == false {
            ranges.append(text.distance(from: text.startIndex, to: found.lowerBound)..<text.distance(from: text.startIndex, to: found.upperBound))
            start = found.upperBound
        }
        return ranges
    }
}
