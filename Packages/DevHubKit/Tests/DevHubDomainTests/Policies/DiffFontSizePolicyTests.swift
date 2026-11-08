import Testing
@testable import DevHubDomain

@Suite struct DiffFontSizePolicyTests {
    @Test func aSizeOutsideTheRangeIsClampedToItsEdge() {
        #expect(DiffFontSizePolicy.clamped(4) == DiffFontSizePolicy.range.lowerBound)
        #expect(DiffFontSizePolicy.clamped(40) == DiffFontSizePolicy.range.upperBound)
        #expect(DiffFontSizePolicy.clamped(13) == 13)
    }

    @Test func aStepChangesTheSizeAndStopsAtTheEdges() {
        #expect(DiffFontSizePolicy.changed(DiffFontSizePolicy.standard, by: 1) == DiffFontSizePolicy.standard + 1)
        #expect(DiffFontSizePolicy.changed(DiffFontSizePolicy.range.upperBound, by: 1) == DiffFontSizePolicy.range.upperBound)
        #expect(DiffFontSizePolicy.changed(DiffFontSizePolicy.range.lowerBound, by: -1) == DiffFontSizePolicy.range.lowerBound)
    }
}
