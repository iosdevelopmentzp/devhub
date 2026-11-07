import DevHubDomain
import DevHubUI
import Testing
@testable import DevHubPresentation

@Suite struct SplitDiffMapperTests {
    private func line(_ id: Int, _ text: String) -> DiffLineModel {
        DiffMapper.line(id: id, text: text, numbers: .none)
    }

    @Test func removedAndAddedLinesOfABlockSitNextToEachOther() {
        let lines = [line(0, "@@ -1,4 +1,4 @@"), line(1, " same"), line(2, "-a"), line(3, "-b"), line(4, "+c"), line(5, " end")]

        let rows = SplitDiffMapper.rows(from: lines)

        #expect(rows.map(\.id) == [0, 1, 2, 3, 5])
        #expect(rows[0].header == lines[0])
        #expect(rows[0].old == nil && rows[0].new == nil)
        #expect(rows[1].old == lines[1] && rows[1].new == lines[1])
        #expect(rows[2].old == lines[2] && rows[2].new == lines[4])
        #expect(rows[3].old == lines[3] && rows[3].new == nil)
        #expect(rows[4].old == lines[5] && rows[4].new == lines[5])
        #expect(rows[2].lineIDs == [2, 4])
        #expect(rows[0].lineIDs == [0])
    }

    @Test func anAddedLineWithoutARemovedOneLeavesTheOldSideEmpty() {
        let rows = SplitDiffMapper.rows(from: [line(0, "+only"), line(1, "\\ No newline at end of file"), line(2, "-gone")])

        #expect(rows.map(\.id) == [0, 2])
        #expect(rows[0].old == nil && rows[0].new?.id == 0)
        #expect(rows[1].old?.id == 2 && rows[1].new == nil)
    }

    @Test func noLinesGiveNoRows() {
        #expect(SplitDiffMapper.rows(from: []).isEmpty)
    }
}
