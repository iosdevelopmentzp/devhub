import Testing
@testable import DevHubPresentation

@Suite struct NotificationSymbolTests {
    @Test func theSignGoesBeforeTheTitle() {
        #expect(NotificationSymbol.title("Built App", symbol: .success, showsEmoji: true) == "✅ Built App")
        #expect(NotificationSymbol.title("Build failed: App", symbol: .failure, showsEmoji: true) == "❌ Build failed: App")
    }

    @Test func noSymbolOrTheSwitchOffKeepsTheTitle() {
        #expect(NotificationSymbol.title("Done", symbol: nil, showsEmoji: true) == "Done")
        #expect(NotificationSymbol.title("Built App", symbol: .success, showsEmoji: false) == "Built App")
    }

    @Test func everySymbolIsDifferent() {
        let signs = NotificationSymbol.allCases.map(\.rawValue)

        #expect(Set(signs).count == signs.count)
    }
}
