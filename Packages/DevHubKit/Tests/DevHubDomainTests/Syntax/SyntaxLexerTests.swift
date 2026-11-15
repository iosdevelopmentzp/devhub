import Testing
@testable import DevHubDomain

@Suite struct SyntaxLexerTests {
    @Test func linesShareOneStateFromTheStart() {
        let tokens = SyntaxLexer.tokens(in: ["/* a", "b */ let x = 1"], language: .swift)

        #expect(tokens.map { $0.map(\.kind) } == [[.comment], [.comment, .keyword, .number]])
    }

    @Test func anEmptyLineHasNoTokens() {
        var state = SyntaxState.blockComment(depth: 2)

        #expect(SyntaxLexer.tokens(in: "", language: .swift, state: &state).isEmpty)
        #expect(state == .blockComment(depth: 2))
    }
}
