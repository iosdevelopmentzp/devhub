import DevHubDomain
import Testing
@testable import DevHubData

@Suite struct GitDiffOutputParserTests {
    @Test func keepsTheFirstLinesAndCountsTheRest() {
        let diff = GitDiffOutputParser.parse("a\nb\nc\nd", maxLines: 3)

        #expect(diff == GitDiff(lines: ["a", "b", "c"], droppedLines: 1, isBinary: false))
    }

    @Test func marksABinaryFile() {
        #expect(GitDiffOutputParser.parse("diff --git a/x b/x\nBinary files a/x and b/x differ", maxLines: 10).isBinary)
    }
}
