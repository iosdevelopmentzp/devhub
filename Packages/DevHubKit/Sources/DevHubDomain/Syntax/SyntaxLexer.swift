import Foundation

package enum SyntaxLexer {

    package static func tokens(in line: String, language: SyntaxLanguage, state: inout SyntaxState) -> [SyntaxToken] {
        let scalars = Array(line.unicodeScalars)
        let scalarTokens: [SyntaxToken]
        switch language {
        case .swift:
            var scanner = SwiftScanner(scalars: scalars, state: state)
            scanner.run()
            state = scanner.state
            scalarTokens = scanner.tokens
        }
        return characterTokens(scalarTokens, in: line, scalarCount: scalars.count)
    }

    package static func tokens(in lines: [String], language: SyntaxLanguage) -> [[SyntaxToken]] {
        var state = SyntaxState.code
        return lines.map { tokens(in: $0, language: language, state: &state) }
    }

    private static func characterTokens(_ tokens: [SyntaxToken], in line: String, scalarCount: Int) -> [SyntaxToken] {
        guard tokens.isEmpty == false, line.count != scalarCount else { return tokens }
        var characterOffset = Array(repeating: 0, count: scalarCount + 1)
        var scalar = 0
        for (index, character) in line.enumerated() {
            for _ in character.unicodeScalars {
                characterOffset[scalar] = index
                scalar += 1
            }
        }
        characterOffset[scalarCount] = line.count
        return tokens.map { SyntaxToken(range: characterOffset[$0.range.lowerBound]..<characterOffset[$0.range.upperBound], kind: $0.kind) }
    }
}
