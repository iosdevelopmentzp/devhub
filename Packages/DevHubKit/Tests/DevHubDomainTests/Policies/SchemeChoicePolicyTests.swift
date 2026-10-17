import Testing
@testable import DevHubDomain

@Suite struct SchemeChoicePolicyTests {
    @Test func availableSavedSchemeWins() {
        let result = SchemeChoicePolicy.choose(available: ["App", "Saved"], saved: "Saved", current: "App", projectDefault: "App")

        #expect(result == "Saved")
    }

    @Test func noSchemesGivesNil() {
        #expect(SchemeChoicePolicy.choose(available: [], saved: "Saved", current: "App", projectDefault: "App") == nil)
    }

    @Test func availableCurrentSchemeIsKept() {
        let result = SchemeChoicePolicy.choose(available: ["App", "Other"], saved: "Gone", current: "Other", projectDefault: "App")

        #expect(result == nil)
    }

    @Test func projectDefaultIsChosenWhenCurrentIsGone() {
        let result = SchemeChoicePolicy.choose(available: ["Other", "App"], saved: nil, current: "Gone", projectDefault: "App")

        #expect(result == "App")
    }

    @Test func firstSchemeIsChosenWhenTheDefaultIsGoneToo() {
        let result = SchemeChoicePolicy.choose(available: ["First", "Second"], saved: nil, current: "Gone", projectDefault: "App")

        #expect(result == "First")
    }
}
