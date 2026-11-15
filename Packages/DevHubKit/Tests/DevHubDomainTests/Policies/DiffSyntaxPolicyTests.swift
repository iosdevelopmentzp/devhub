import Testing
@testable import DevHubDomain

@Suite struct DiffSyntaxPolicyTests {
    @Test func tokensAreShiftedPastThePrefixAndHeadersHaveNone() {
        let lines = ["@@ -1,2 +1,2 @@", " let a = 1", "-let b = \"x\"", "+let b = 2", "\\ No newline at end of file"]

        let tokens = DiffSyntaxPolicy.tokens(forHunkLines: lines, language: .swift)

        #expect(tokens[0].isEmpty)
        #expect(tokens[1] == [SyntaxToken(range: 1..<4, kind: .keyword), SyntaxToken(range: 9..<10, kind: .number)])
        #expect(tokens[2] == [SyntaxToken(range: 1..<4, kind: .keyword), SyntaxToken(range: 9..<12, kind: .string)])
        #expect(tokens[3] == [SyntaxToken(range: 1..<4, kind: .keyword), SyntaxToken(range: 9..<10, kind: .number)])
        #expect(tokens[4].isEmpty)
    }

    @Test func theOldAndTheNewSideKeepTheirOwnState() {
        let lines = ["@@ -1,3 +1,3 @@", "-/* old comment", "+let a = 1", " let b = 2", "-*/ let c = 3"]

        let tokens = DiffSyntaxPolicy.tokens(forHunkLines: lines, language: .swift)

        #expect(tokens[1].map(\.kind) == [.comment])
        #expect(tokens[2].map(\.kind) == [.keyword, .number])
        #expect(tokens[3].map(\.kind) == [.keyword, .number])
        #expect(tokens[4].map(\.kind) == [.comment, .keyword, .number])
    }

    @Test func aHunkHeaderResetsBothStates() {
        let lines = ["@@ -1 +1 @@", "+/* open", "@@ -9 +9 @@", "+let a = 1"]

        let tokens = DiffSyntaxPolicy.tokens(forHunkLines: lines, language: .swift)

        #expect(tokens[3].map(\.kind) == [.keyword, .number])
    }

    @Test func anEmptyLineHasNoTokens() {
        #expect(DiffSyntaxPolicy.tokens(forHunkLines: ["", "+"], language: .swift) == [[], []])
    }
}
