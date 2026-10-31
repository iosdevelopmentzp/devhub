import Testing
@testable import DevHubDomain

@Suite struct DiffContextExpansionTests {
    private let file = ["a", "b", "c", "d", "e", "f", "g", "h"]

    @Test func theGapsBetweenHunksComeFromTheFile() throws {
        let diff = GitDiff(lines: ["@@ -2,2 +2,2 @@", " b", "-old", "+c", "@@ -6,1 +6,2 @@", "+f", " g"], droppedLines: 0, isBinary: false)

        let expanded = try #require(DiffContextExpansion.expanded(diff, fileLines: file))

        #expect(expanded.lines == ["@@ -1,7 +1,8 @@", " a", " b", "-old", "+c", " d", " e", "+f", " g", " h"])
        #expect(DiffLineNumbering.numbers(for: expanded.lines).map(\.new) == [nil, 1, 2, nil, 3, 4, 5, 6, 7, 8])
        #expect(DiffLineNumbering.numbers(for: expanded.lines).map(\.old) == [nil, 1, 2, 3, nil, 4, 5, nil, 6, 7])
    }

    @Test func headerLinesBeforeTheFirstHunkAreDropped() throws {
        let diff = GitDiff(lines: ["diff --git a/x b/x", "@@ -1 +1 @@", "-a", "+A"], droppedLines: 0, isBinary: false)

        let expanded = try #require(DiffContextExpansion.expanded(diff, fileLines: ["A", "b"]))

        #expect(expanded.lines == ["@@ -1,2 +1,2 @@", "-a", "+A", " b"])
    }

    @Test func aDiffThatDoesNotFitTheFileGivesNothing() {
        let beyond = GitDiff(lines: ["@@ -20,1 +20,1 @@", "-x", "+y"], droppedLines: 0, isBinary: false)
        let overlapping = GitDiff(lines: ["@@ -3,2 +3,2 @@", "-c", "+C", " d", "@@ -2,1 +2,1 @@", "-b", "+B"], droppedLines: 0, isBinary: false)

        #expect(DiffContextExpansion.expanded(beyond, fileLines: file) == nil)
        #expect(DiffContextExpansion.expanded(overlapping, fileLines: file) == nil)
    }

    @Test func binaryTruncatedAndHunklessDiffsGiveNothing() {
        #expect(DiffContextExpansion.expanded(GitDiff(lines: ["@@ -1 +1 @@", "+a"], droppedLines: 3, isBinary: false), fileLines: file) == nil)
        #expect(DiffContextExpansion.expanded(GitDiff(lines: ["Binary"], droppedLines: 0, isBinary: true), fileLines: file) == nil)
        #expect(DiffContextExpansion.expanded(GitDiff(lines: [], droppedLines: 0, isBinary: false), fileLines: file) == nil)
    }
}
