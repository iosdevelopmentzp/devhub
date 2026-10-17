import Testing
@testable import DevHubPresentation

@Suite struct PreferenceKeysTests {
    @Test func keysKeepTheirSavedNames() {
        #expect(PreferenceKeys.projects == "app.projects")
        #expect(PreferenceKeys.selectedProject == "app.selectedProject")
        #expect(PreferenceKeys.settings == "app.settings")
    }
}
