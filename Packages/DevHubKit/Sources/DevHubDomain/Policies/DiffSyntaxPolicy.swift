import Foundation

package enum DiffSyntaxPolicy {

    package static func tokens(forHunkLines lines: [String], language: SyntaxLanguage) -> [[SyntaxToken]] {
        var old = SyntaxState.code
        var new = SyntaxState.code
        return lines.map { line in
            guard let prefix = line.first else { return [] }
            guard line.hasPrefix("@@") == false else {
                old = .code
                new = .code
                return []
            }
            let text = String(line.dropFirst())
            switch prefix {
            case "-":
                return shifted(SyntaxLexer.tokens(in: text, language: language, state: &old))
            case "+":
                return shifted(SyntaxLexer.tokens(in: text, language: language, state: &new))
            case " ":
                _ = SyntaxLexer.tokens(in: text, language: language, state: &old)
                return shifted(SyntaxLexer.tokens(in: text, language: language, state: &new))
            default:
                return []
            }
        }
    }

    private static func shifted(_ tokens: [SyntaxToken]) -> [SyntaxToken] {
        tokens.map { SyntaxToken(range: ($0.range.lowerBound + 1)..<($0.range.upperBound + 1), kind: $0.kind) }
    }
}
