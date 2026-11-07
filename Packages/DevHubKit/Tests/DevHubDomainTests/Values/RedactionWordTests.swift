import Testing
@testable import DevHubDomain

@Suite struct RedactionWordTests {
    @Test func linesBecomeWordsAndPatterns() {
        let text = "# the owner's words\nExample Corp\n\n  re: ABC-[0-9]+  \nre:\n  \nsecond\n"

        #expect(RedactionWord.parse(text) == [.word("Example Corp"), .pattern("ABC-[0-9]+"), .word("second")])
        #expect(RedactionWord.parse("").isEmpty)
    }
}
