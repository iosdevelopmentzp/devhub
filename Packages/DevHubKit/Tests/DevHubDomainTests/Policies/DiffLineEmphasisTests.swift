import Testing
@testable import DevHubDomain

@Suite struct DiffLineEmphasisTests {
    @Test func removedLinesPairWithTheAddedLinesOfTheSameBlockInOrder() {
        let lines = ["@@ -1,6 +1,6 @@", "-a", "-b", "+c", "+d", "+e", " same", "-f", "\\ No newline at end of file", "+g", "+h", " same", "+i"]

        #expect(DiffLineEmphasis.pairs(in: lines) == [
            DiffLineEmphasis.Pair(removed: 1, added: 3),
            DiffLineEmphasis.Pair(removed: 2, added: 4),
            DiffLineEmphasis.Pair(removed: 7, added: 9),
        ])
        #expect(DiffLineEmphasis.pairs(in: ["+a", "-b"]) == [])
        #expect(DiffLineEmphasis.pairs(in: []).isEmpty)
    }

    @Test func onlyTheChangedWordsAreEmphasized() {
        let ranges = DiffLineEmphasis.ranges(removed: "    let value: Int = 1", added: "    let value: String = 1")

        #expect(ranges == DiffLineEmphasis.Ranges(removed: [15..<18], added: [15..<21]))
    }

    @Test func neighbouringChangedTokensMergeIntoOneRange() {
        let ranges = DiffLineEmphasis.ranges(removed: "foo(a, b)", added: "foo(a, b, c)")

        #expect(ranges == DiffLineEmphasis.Ranges(removed: [], added: [8..<11]))
    }

    @Test func identicalLinesHaveNoEmphasis() {
        #expect(DiffLineEmphasis.ranges(removed: "same", added: "same") == DiffLineEmphasis.Ranges(removed: [], added: []))
    }

    @Test func linesThatShareLittleGetNoEmphasis() {
        #expect(DiffLineEmphasis.ranges(removed: "return nil", added: "throw TestError.missing(\"x\")") == nil)
        #expect(DiffLineEmphasis.ranges(removed: "", added: "new") == nil)
    }

    @Test func veryLongLinesAreSkipped() {
        let long = Array(repeating: "a ", count: DiffLineEmphasis.tokenLimit).joined()

        #expect(DiffLineEmphasis.ranges(removed: long, added: long + "b") == nil)
    }
}
