import SwiftUI
import Testing
@testable import DevHubUI

@Suite struct SyntaxColorTests {
    @Test func everyKindHasItsThemeColor() {
        #expect(SyntaxColor.keyword.color == Theme.syntaxKeyword)
        #expect(SyntaxColor.type.color == Theme.syntaxType)
        #expect(SyntaxColor.string.color == Theme.syntaxString)
        #expect(SyntaxColor.number.color == Theme.syntaxNumber)
        #expect(SyntaxColor.comment.color == Theme.syntaxComment)
        #expect(SyntaxColor.attribute.color == Theme.syntaxAttribute)
        #expect(SyntaxColor.directive.color == Theme.syntaxDirective)
        #expect(Set(SyntaxColor.allCases.map(\.color)).count == SyntaxColor.allCases.count)
    }
}
