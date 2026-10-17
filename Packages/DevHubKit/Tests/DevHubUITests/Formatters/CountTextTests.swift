import Testing
@testable import DevHubUI

@Suite struct CountTextTests {
    @Test func countUsesSingularForOne() {
        #expect(CountText.count(1, "file") == "1 file")
        #expect(CountText.count(1, "child", "children") == "1 child")
    }

    @Test func countAddsSWithoutExplicitPlural() {
        #expect(CountText.count(0, "file") == "0 files")
        #expect(CountText.count(3, "file") == "3 files")
    }

    @Test func countUsesExplicitPlural() {
        #expect(CountText.count(2, "child", "children") == "2 children")
        #expect(CountText.count(0, "child", "children") == "0 children")
    }

    @Test func invariantNeverChangesTheNoun() {
        #expect(CountText.invariant(1, "devices") == "1 devices")
        #expect(CountText.invariant(5, "devices") == "5 devices")
    }
}
