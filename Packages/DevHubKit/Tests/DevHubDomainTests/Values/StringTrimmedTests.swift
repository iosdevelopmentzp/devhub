import Testing
@testable import DevHubDomain

@Suite struct StringTrimmedTests {
    @Test func removesSpacesAndNewlinesAtBothEnds() {
        #expect("  feature \n\t".trimmed == "feature")
    }

    @Test func keepsInnerSpaces() {
        #expect(" a b ".trimmed == "a b")
    }

    @Test func blankBecomesEmpty() {
        #expect(" \n ".trimmed.isEmpty)
    }
}
