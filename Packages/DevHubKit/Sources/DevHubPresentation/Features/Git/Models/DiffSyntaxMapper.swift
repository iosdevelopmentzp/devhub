import Foundation
import DevHubDomain
import DevHubUI

enum DiffSyntaxMapper {

    static func spans(for tokens: [SyntaxToken]) -> [DiffSyntaxSpan] {
        tokens.map { DiffSyntaxSpan(range: $0.range, color: color(for: $0.kind)) }
    }

    static func color(for kind: SyntaxTokenKind) -> SyntaxColor {
        switch kind {
        case .keyword: .keyword
        case .type: .type
        case .string: .string
        case .number: .number
        case .comment: .comment
        case .attribute: .attribute
        case .directive: .directive
        }
    }

    static func language(forPath path: String, syntaxColors: Bool) -> SyntaxLanguage? {
        guard syntaxColors else { return nil }
        return SyntaxLanguage.language(forPath: path)
    }
}
