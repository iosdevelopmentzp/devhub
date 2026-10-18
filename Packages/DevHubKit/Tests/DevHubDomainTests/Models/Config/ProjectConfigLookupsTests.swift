import Testing
@testable import DevHubDomain

@Suite struct ProjectConfigLookupsTests {
    @Test func knownBundleIDsJoinTheConfigAndTheDetectedOne() {
        let config = ProjectConfig(xcode: XcodeConfig(bundleID: "com.example.app", bundleIDs: ["Beta": "com.example.app.beta"]))

        #expect(config.knownBundleIDs(detected: "com.example.detected") == ["com.example.app", "com.example.app.beta", "com.example.detected"])
        #expect(ProjectConfig().knownBundleIDs(detected: nil).isEmpty)
    }
}
