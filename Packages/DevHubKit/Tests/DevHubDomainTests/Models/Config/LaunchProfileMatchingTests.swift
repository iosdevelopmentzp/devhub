import Testing
@testable import DevHubDomain

@Suite struct LaunchProfileMatchingTests {
    private let profiles = [
        LaunchProfile(id: "staging", title: "Staging"),
        LaunchProfile(id: "prod", title: "Production"),
    ]

    @Test func matchesTheIDThenTheTitle() {
        #expect(profiles.profile(matching: "prod")?.title == "Production")
        #expect(profiles.profile(matching: " production ")?.id == "prod")
        #expect(profiles.profile(matching: "STAGING")?.id == "staging")
    }

    @Test func unknownOrEmptyValuesMatchNothing() {
        #expect(profiles.profile(matching: "dev") == nil)
        #expect(profiles.profile(matching: " ") == nil)
        #expect(profiles.profile(matching: nil) == nil)
    }
}
