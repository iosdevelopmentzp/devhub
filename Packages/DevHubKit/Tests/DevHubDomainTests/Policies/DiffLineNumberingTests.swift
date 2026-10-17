import Testing
@testable import DevHubDomain

@Suite struct DiffLineNumberingTests {
    @Test func numbersFollowTheHunks() {
        let lines = ["diff --git", "@@ -10,3 +20,4 @@", " a", "-b", "+c", "+d", "\\ No newline at end of file", "@@ -50 +60 @@", " z"]

        #expect(DiffLineNumbering.numbers(for: lines) == [
            .none,
            .none,
            DiffLineNumbers(old: 10, new: 20),
            DiffLineNumbers(old: 11, new: nil),
            DiffLineNumbers(old: nil, new: 21),
            DiffLineNumbers(old: nil, new: 22),
            .none,
            .none,
            DiffLineNumbers(old: 50, new: 60),
        ])
    }

    @Test func aBrokenHunkHeaderGivesNoNumbers() {
        #expect(DiffLineNumbering.numbers(for: ["@@ broken", " a"]) == [.none, .none])
    }
}
