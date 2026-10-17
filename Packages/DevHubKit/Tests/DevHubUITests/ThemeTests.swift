import SwiftUI
import Testing
@testable import DevHubUI

@Suite struct ThemeTests {
    @Test func surfacesAreNearWhiteAndWhite() {
        #expect(Theme.base == Color(white: 0.97))
        #expect(Theme.surface == .white)
    }

    @Test func overlaysAreTranslucent() {
        #expect(Theme.border == Color.primary.opacity(0.12))
        #expect(Theme.hover == Color.primary.opacity(0.05))
        #expect(Theme.shadow == Color.black.opacity(0.08))
    }
}
