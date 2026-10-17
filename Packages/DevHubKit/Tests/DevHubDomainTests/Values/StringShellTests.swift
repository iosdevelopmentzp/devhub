import Testing
@testable import DevHubDomain

@Suite struct StringShellTests {
    @Test func wrapsPlainTextInSingleQuotes() {
        #expect("My Project".shellQuoted == "'My Project'")
    }

    @Test func escapesSingleQuotes() {
        #expect("it's".shellQuoted == #"'it'\''s'"#)
    }

    @Test func quotesAnEmptyString() {
        #expect("".shellQuoted == "''")
    }

    @Test func leavesShellCharactersInsideTheQuotes() {
        #expect("$(rm -rf) && `x`".shellQuoted == "'$(rm -rf) && `x`'")
    }
}
