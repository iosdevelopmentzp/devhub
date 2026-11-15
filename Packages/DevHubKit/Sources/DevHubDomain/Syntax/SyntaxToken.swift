import Foundation

package struct SyntaxToken: Hashable, Sendable {
    package let range: Range<Int>
    package let kind: SyntaxTokenKind

    package init(range: Range<Int>, kind: SyntaxTokenKind) {
        self.range = range
        self.kind = kind
    }
}
