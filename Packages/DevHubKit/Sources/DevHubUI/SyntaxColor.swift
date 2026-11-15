import SwiftUI

package enum SyntaxColor: Hashable, CaseIterable, Sendable {
    case keyword
    case type
    case string
    case number
    case comment
    case attribute
    case directive

    package var color: Color {
        switch self {
        case .keyword: Theme.syntaxKeyword
        case .type: Theme.syntaxType
        case .string: Theme.syntaxString
        case .number: Theme.syntaxNumber
        case .comment: Theme.syntaxComment
        case .attribute: Theme.syntaxAttribute
        case .directive: Theme.syntaxDirective
        }
    }
}
