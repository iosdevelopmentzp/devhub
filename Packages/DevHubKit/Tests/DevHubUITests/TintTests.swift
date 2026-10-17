import SwiftUI
import Testing
@testable import DevHubUI

@Suite struct TintTests {
    @Test func everyTintMapsToItsColor() {
        let expected: [(Tint, Color)] = [
            (.green, .green),
            (.orange, .orange),
            (.red, .red),
            (.blue, .blue),
            (.purple, .purple),
            (.indigo, .indigo),
            (.teal, .teal),
            (.pink, .pink),
            (.gray, .gray),
            (.secondary, .secondary)
        ]

        for (tint, color) in expected {
            #expect(tint.color == color)
            #expect(tint.color != .clear)
        }
        #expect(Set(expected.map(\.0)).count == 10)
    }
}
