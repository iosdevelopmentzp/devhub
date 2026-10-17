import Testing
@testable import DevHubDomain

@Suite struct SchemeChoicePolicyTests {
    @Test func availableSavedSchemeWins() {
        let result = SchemeChoicePolicy.choose(available: ["App", "Saved"], saved: "Saved", configured: nil, current: "App", projectDefault: "App")

        #expect(result == "Saved")
    }

    @Test func noSchemesGivesNil() {
        #expect(SchemeChoicePolicy.choose(available: [], saved: "Saved", configured: nil, current: "App", projectDefault: "App") == nil)
    }

    @Test func availableCurrentSchemeIsKept() {
        let result = SchemeChoicePolicy.choose(available: ["App", "Other"], saved: "Gone", configured: nil, current: "Other", projectDefault: "App")

        #expect(result == nil)
    }

    @Test func projectDefaultIsChosenWhenCurrentIsGone() {
        let result = SchemeChoicePolicy.choose(available: ["Other", "App"], saved: nil, configured: nil, current: "Gone", projectDefault: "App")

        #expect(result == "App")
    }

    @Test func firstSchemeIsChosenWhenTheDefaultIsGoneToo() {
        let result = SchemeChoicePolicy.choose(available: ["First", "Second"], saved: nil, configured: nil, current: "Gone", projectDefault: "App")

        #expect(result == "First")
    }

    @Test func theConfiguredSchemeWinsOverTheCurrentOneWhenNothingIsSaved() {
        #expect(SchemeChoicePolicy.choose(available: ["App", "Tools"], saved: nil, configured: "Tools", current: "App", projectDefault: "App") == "Tools")
        #expect(SchemeChoicePolicy.choose(available: ["App", "Tools"], saved: "App", configured: "Tools", current: "App", projectDefault: "App") == "App")
        #expect(SchemeChoicePolicy.choose(available: ["App"], saved: nil, configured: "Gone", current: "App", projectDefault: "App") == nil)
    }
}
