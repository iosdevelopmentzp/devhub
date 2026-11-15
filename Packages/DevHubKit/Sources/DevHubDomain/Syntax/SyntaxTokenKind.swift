import Foundation

package enum SyntaxTokenKind: Hashable, CaseIterable, Sendable {
    case keyword
    case type
    case string
    case number
    case comment
    case attribute
    case directive
}
