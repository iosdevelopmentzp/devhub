import Testing
@testable import DevHubDomain

@Suite struct ManualSchemePolicyTests {

    @Test func optionsAppendManualSchemesThatAreNotVisible() {
        #expect(ManualSchemePolicy.options(visible: ["App", "Widget"], manual: ["Widget", "Tools"]) == ["App", "Widget", "Tools"])
    }

    @Test func addingTrimsTheName() {
        #expect(ManualSchemePolicy.adding("  Tools \n", to: [], visible: ["App"]) == ["Tools"])
    }

    @Test func addingIgnoresEmptyVisibleAndRepeatedNames() {
        #expect(ManualSchemePolicy.adding("  ", to: ["Tools"], visible: ["App"]) == ["Tools"])
        #expect(ManualSchemePolicy.adding("App", to: ["Tools"], visible: ["App"]) == ["Tools"])
        #expect(ManualSchemePolicy.adding("Tools", to: ["Tools"], visible: ["App"]) == ["Tools"])
    }

    @Test func suggestionsSkipVisibleAndManualNames() {
        let suggestions = ManualSchemePolicy.suggestions(listed: ["App", "Tools", "Widget", "AppTests"], visible: ["App"], manual: ["Tools"])

        #expect(suggestions == ["Widget", "AppTests"])
    }
}
