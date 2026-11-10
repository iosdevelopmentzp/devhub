import DevHubDomain
import DevHubUI
import Testing
@testable import DevHubPresentation

@Suite struct DiffFindPolicyTests {
    private let diff = GitDiff(
        lines: ["diff --git a/x b/x", "@@ -1,3 +1,3 @@ func value()", " let value = 1", "-let Value = 2", "+let value = 3; let VALUE = 4", "\\ No newline at end of value"],
        droppedLines: 0,
        isBinary: false
    )

    @Test func matchesIgnoreCaseAndCarryTheLineOfEachHit() {
        let matches = DiffFindPolicy.matches(in: diff, path: "a.swift", query: "value")

        #expect(matches == [
            DiffFindMatch(path: "a.swift", lineID: 1, range: 5..<10, line: 1, isOld: false),
            DiffFindMatch(path: "a.swift", lineID: 2, range: 5..<10, line: 2, isOld: true),
            DiffFindMatch(path: "a.swift", lineID: 3, range: 5..<10, line: 2, isOld: false),
            DiffFindMatch(path: "a.swift", lineID: 3, range: 20..<25, line: 2, isOld: false),
        ])
    }

    @Test func linesWithoutANumberAndBinaryOrEmptyQueriesGiveNoMatch() {
        let headerOnly = GitDiff(lines: ["@@ -1 +1 @@ value"], droppedLines: 0, isBinary: false)
        let binary = GitDiff(lines: ["value"], droppedLines: 0, isBinary: true)

        #expect(DiffFindPolicy.matches(in: headerOnly, path: "a", query: "value").isEmpty)
        #expect(DiffFindPolicy.matches(in: binary, path: "a", query: "value").isEmpty)
        #expect(DiffFindPolicy.matches(in: diff, path: "a", query: "").isEmpty)
        #expect(DiffFindPolicy.matches(in: diff, path: "a", query: "missing").isEmpty)
    }

    @Test func rangesDoNotOverlap() {
        #expect(DiffFindPolicy.ranges(of: "aa", in: "aaa") == [0..<2])
        #expect(DiffFindPolicy.ranges(of: "A", in: "banana") == [1..<2, 3..<4, 5..<6])
        #expect(DiffFindPolicy.ranges(of: "", in: "banana").isEmpty)
    }

    @Test func markedLinesCarryTheirRangesAndTheCurrentMatch() throws {
        guard case .lines(let lines, _) = DiffMapper.model(for: diff) else {
            Issue.record("Expected lines")
            return
        }
        let current = DiffFindMatch(path: "a.swift", lineID: 3, range: 20..<25, line: 2, isOld: false)

        let marked = DiffFindPolicy.marked(lines, path: "a.swift", find: DiffFindState(query: "value", current: current))
        let elsewhere = DiffFindPolicy.marked(lines, path: "b.swift", find: DiffFindState(query: "value", current: current))

        #expect(marked.map(\.findRanges) == [[], [5..<10], [5..<10], [5..<10, 20..<25], []])
        #expect(marked.map(\.currentFindRange) == [nil, nil, nil, 20..<25, nil])
        #expect(elsewhere.map(\.currentFindRange) == [nil, nil, nil, nil, nil])
        #expect(DiffFindPolicy.marked(lines, path: "a.swift", find: .initial) == lines)
    }
}
