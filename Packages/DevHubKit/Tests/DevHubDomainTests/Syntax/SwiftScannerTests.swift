import Testing
@testable import DevHubDomain

@Suite struct SwiftScannerTests {
    @Test func keywordsTypesAndAttributesAreTokens() {
        let tokens = tokens("@MainActor final class Store: Sendable { let count = 3 }")

        #expect(tokens == [
            SyntaxToken(range: 0..<10, kind: .attribute),
            SyntaxToken(range: 11..<16, kind: .keyword),
            SyntaxToken(range: 17..<22, kind: .keyword),
            SyntaxToken(range: 23..<28, kind: .type),
            SyntaxToken(range: 30..<38, kind: .type),
            SyntaxToken(range: 41..<44, kind: .keyword),
            SyntaxToken(range: 53..<54, kind: .number),
        ])
    }

    @Test func numbersCoverHexBinaryFloatsAndUnderscores() {
        #expect(tokens("0xFF_AA 0b1010 1_000.5e-3 42abc").map(\.range) == [0..<7, 8..<14, 15..<25, 26..<28])
        #expect(tokens("42abc").map(\.kind) == [.number])
        #expect(tokens("x1").isEmpty)
    }

    @Test func lineCommentsRunToTheEnd() {
        let tokens = tokens("let a = 1 // let b = \"x\"")

        #expect(tokens.map(\.kind) == [.keyword, .number, .comment])
        #expect(tokens.last?.range == 10..<24)
        #expect(self.tokens("/// Documentation").map(\.kind) == [.comment])
    }

    @Test func blockCommentsNestAndCrossLines() {
        var state = SyntaxState.code

        let first = SyntaxLexer.tokens(in: "let a = 1 /* start /* inner */", language: .swift, state: &state)
        #expect(first.map(\.kind) == [.keyword, .number, .comment])
        #expect(state == .blockComment(depth: 1))

        let second = SyntaxLexer.tokens(in: "still a comment let", language: .swift, state: &state)
        #expect(second == [SyntaxToken(range: 0..<19, kind: .comment)])
        #expect(state == .blockComment(depth: 1))

        let third = SyntaxLexer.tokens(in: "end */ let b = 2", language: .swift, state: &state)
        #expect(third.map(\.kind) == [.comment, .keyword, .number])
        #expect(third.first?.range == 0..<6)
        #expect(state == .code)
    }

    @Test func stringsKeepEscapesAndColorInterpolatedCode() {
        let tokens = tokens("print(\"a \\\"quoted\\\" \\(count + 1) end\")")

        #expect(tokens == [
            SyntaxToken(range: 6..<22, kind: .string),
            SyntaxToken(range: 30..<31, kind: .number),
            SyntaxToken(range: 31..<37, kind: .string),
        ])
    }

    @Test func rawStringsIgnorePlainBackslashesAndTakeHashInterpolation() {
        #expect(tokens(##"let r = #"a \n "quoted" \#(x) end"#"##) == [
            SyntaxToken(range: 0..<3, kind: .keyword),
            SyntaxToken(range: 8..<27, kind: .string),
            SyntaxToken(range: 28..<35, kind: .string),
        ])
    }

    @Test func multilineStringsCarryTheirStateAcrossLines() {
        var state = SyntaxState.code

        let first = SyntaxLexer.tokens(in: "let text = \"\"\"", language: .swift, state: &state)
        #expect(first.map(\.kind) == [.keyword, .string])
        #expect(state == .multilineString(hashes: 0))

        let second = SyntaxLexer.tokens(in: "  let not = \"a keyword\"", language: .swift, state: &state)
        #expect(second == [SyntaxToken(range: 0..<23, kind: .string)])

        let third = SyntaxLexer.tokens(in: "  \"\"\" + suffix", language: .swift, state: &state)
        #expect(third == [SyntaxToken(range: 0..<5, kind: .string)])
        #expect(state == .code)
    }

    @Test func rawMultilineStringsNeedTheHashesToClose() {
        var state = SyntaxState.code

        _ = SyntaxLexer.tokens(in: "let text = #\"\"\"", language: .swift, state: &state)
        #expect(state == .multilineString(hashes: 1))

        _ = SyntaxLexer.tokens(in: "\"\"\" still inside", language: .swift, state: &state)
        #expect(state == .multilineString(hashes: 1))

        _ = SyntaxLexer.tokens(in: "\"\"\"# let", language: .swift, state: &state)
        #expect(state == .code)
    }

    @Test func directivesAndMacrosStartWithAHash() {
        let tokens = tokens("#if DEBUG #Preview { } #endif")

        #expect(tokens.map(\.kind) == [.directive, .type, .directive, .directive])
        #expect(tokens[0].range == 0..<3)
    }

    @Test func backtickNamesAndDollarNamesAreNotKeywords() {
        #expect(tokens("let `default` = $0").map(\.kind) == [.keyword])
        #expect(tokens("case .default: break").map(\.kind) == [.keyword, .keyword, .keyword])
    }

    @Test func anUnterminatedStringEndsWithTheLine() {
        var state = SyntaxState.code

        let tokens = SyntaxLexer.tokens(in: "let s = \"open", language: .swift, state: &state)

        #expect(tokens == [SyntaxToken(range: 0..<3, kind: .keyword), SyntaxToken(range: 8..<13, kind: .string)])
        #expect(state == .code)
    }

    @Test func rangesAreCharacterOffsetsWhenTheLineHasCombinedCharacters() {
        let tokens = tokens("let flag = \"🇺🇦\" // done")

        #expect(tokens == [
            SyntaxToken(range: 0..<3, kind: .keyword),
            SyntaxToken(range: 11..<14, kind: .string),
            SyntaxToken(range: 15..<22, kind: .comment),
        ])
    }

    private func tokens(_ line: String) -> [SyntaxToken] {
        var state = SyntaxState.code
        return SyntaxLexer.tokens(in: line, language: .swift, state: &state)
    }
}
