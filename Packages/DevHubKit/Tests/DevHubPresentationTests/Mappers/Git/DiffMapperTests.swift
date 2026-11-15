import DevHubDomain
import DevHubUI
import Testing
@testable import DevHubPresentation

@Suite struct DiffMapperTests {
    @Test func missingDiffIsLoading() {
        #expect(DiffMapper.model(for: nil, language: nil) == .loading)
    }

    @Test func binaryDiffGivesANote() {
        let diff = GitDiff(lines: ["Binary files differ"], droppedLines: 0, isBinary: true)

        #expect(DiffMapper.model(for: diff, language: nil) == .note("Binary file, no text diff"))
    }

    @Test func emptyLinesGiveANote() {
        let note = DiffModel.note("No text changes. Only the file mode or an empty file changed.")

        #expect(DiffMapper.model(for: GitDiff(lines: [], droppedLines: 0, isBinary: false), language: nil) == note)
        #expect(DiffMapper.model(for: GitDiff(lines: ["", ""], droppedLines: 0, isBinary: false), language: nil) == note)
    }

    @Test func headerLinesBeforeTheFirstHunkAreSkipped() {
        let diff = GitDiff(
            lines: ["diff --git a/x b/x", "index 1..2", "@@ -1,2 +1,2 @@", "+new", "-old", " same", ""],
            droppedLines: 0,
            isBinary: false
        )

        let model = DiffMapper.model(for: diff, language: nil)

        #expect(model == .lines(
            [
                DiffLineModel(id: 0, text: "@@ -1,2 +1,2 @@", tint: .blue, foregroundOpacity: 1, backgroundOpacity: 0.06, oldNumber: nil, newNumber: nil),
                DiffLineModel(id: 1, text: "+new", tint: .green, foregroundOpacity: 0.9, backgroundOpacity: 0.08, oldNumber: nil, newNumber: 1),
                DiffLineModel(id: 2, text: "-old", tint: .red, foregroundOpacity: 0.9, backgroundOpacity: 0.08, oldNumber: 1, newNumber: nil),
                DiffLineModel(id: 3, text: " same", tint: nil, foregroundOpacity: 0.8, backgroundOpacity: 0, oldNumber: 2, newNumber: 2),
                DiffLineModel(id: 4, text: " ", tint: nil, foregroundOpacity: 0.8, backgroundOpacity: 0, oldNumber: 3, newNumber: 3)
            ],
            droppedNote: nil
        ))
    }

    @Test func pairedLinesCarryTheirEmphasisShiftedPastThePrefix() {
        let diff = GitDiff(lines: ["@@ -1,2 +1,2 @@", "-let a: Int", "+let a: String", " same"], droppedLines: 0, isBinary: false)

        guard case .lines(let lines, _) = DiffMapper.model(for: diff, language: nil) else {
            Issue.record("Expected lines")
            return
        }
        #expect(lines.map(\.emphasis) == [[], [8..<11], [8..<14], []])
    }

    @Test func withoutHunkEveryLineIsShown() {
        let diff = GitDiff(lines: ["+only"], droppedLines: 0, isBinary: false)

        #expect(DiffMapper.model(for: diff, language: nil) == .lines([DiffMapper.line(id: 0, text: "+only", numbers: .none)], droppedNote: nil))
    }

    @Test func aLanguageAddsSyntaxSpansAndAStrongerBackgroundToChangedLines() {
        let diff = GitDiff(lines: ["@@ -1,2 +1,2 @@", "-let a = 1", "+let a = \"x\"", " func go() {}"], droppedLines: 0, isBinary: false)

        guard case .lines(let lines, _) = DiffMapper.model(for: diff, language: .swift) else {
            Issue.record("Expected lines")
            return
        }
        #expect(lines.map(\.hasSyntaxColors) == [false, true, true, true])
        #expect(lines[0].syntax.isEmpty)
        #expect(lines[1].syntax == [DiffSyntaxSpan(range: 1..<4, color: .keyword), DiffSyntaxSpan(range: 9..<10, color: .number)])
        #expect(lines[2].syntax == [DiffSyntaxSpan(range: 1..<4, color: .keyword), DiffSyntaxSpan(range: 9..<12, color: .string)])
        #expect(lines[3].syntax == [DiffSyntaxSpan(range: 1..<5, color: .keyword)])
        #expect(lines.map(\.backgroundOpacity) == [0.06, DiffMapper.syntaxBackgroundOpacity, DiffMapper.syntaxBackgroundOpacity, 0])
        #expect(lines[1].emphasis == [9..<10])
    }

    @Test func withoutALanguageNoLineHasSyntaxColors() {
        let diff = GitDiff(lines: ["@@ -1 +1 @@", "+let a = 1"], droppedLines: 0, isBinary: false)

        guard case .lines(let lines, _) = DiffMapper.model(for: diff, language: nil) else {
            Issue.record("Expected lines")
            return
        }
        #expect(lines.allSatisfy { $0.hasSyntaxColors == false && $0.syntax.isEmpty })
    }

    @Test func droppedLinesGiveANote() {
        let diff = GitDiff(lines: ["@@ -1 +1 @@"], droppedLines: 42, isBinary: false)

        guard case .lines(_, let droppedNote) = DiffMapper.model(for: diff, language: nil) else {
            Issue.record("Expected lines")
            return
        }
        #expect(droppedNote == "… 42 more lines not shown")
    }
}
