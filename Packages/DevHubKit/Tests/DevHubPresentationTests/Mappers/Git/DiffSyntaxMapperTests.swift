import DevHubDomain
import DevHubUI
import Testing
@testable import DevHubPresentation

@Suite struct DiffSyntaxMapperTests {
    @Test func everyTokenKindHasAColor() {
        #expect(SyntaxTokenKind.allCases.map(DiffSyntaxMapper.color(for:)) == [.keyword, .type, .string, .number, .comment, .attribute, .directive])
    }

    @Test func tokensBecomeSpans() {
        let spans = DiffSyntaxMapper.spans(for: [SyntaxToken(range: 1..<4, kind: .keyword), SyntaxToken(range: 9..<10, kind: .number)])

        #expect(spans == [DiffSyntaxSpan(range: 1..<4, color: .keyword), DiffSyntaxSpan(range: 9..<10, color: .number)])
    }

    @Test func theLanguageNeedsTheSettingAndAKnownExtension() {
        #expect(DiffSyntaxMapper.language(forPath: "A/B.swift", syntaxColors: true) == .swift)
        #expect(DiffSyntaxMapper.language(forPath: "A/B.swift", syntaxColors: false) == nil)
        #expect(DiffSyntaxMapper.language(forPath: "A/B.json", syntaxColors: true) == nil)
    }
}
