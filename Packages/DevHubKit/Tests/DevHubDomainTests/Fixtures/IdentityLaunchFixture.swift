@testable import DevHubDomain

enum IdentityLaunchFixture {
    static let udid = "SIM-1"
    static let bundleID = "com.example.app"
    static let identityConfig = LaunchIdentityConfig(variable: "APP_DEVICE_ID", args: ["-skipOnboarding"])
    static let staging = LaunchProfile(id: "staging", title: "Staging", env: ["API_ENV": "staging"], upstream: "https://api.staging.example.com")

    static let plain = IdentityLaunch(
        simulator: SimulatorFixture.booted(udid),
        bundleID: bundleID,
        plan: .none,
        attachDebugger: false,
        projectPath: "/repo",
        container: nil,
        fallbackAppPath: "/derived/App.app"
    )

    static func plan(identity: String?, profile: LaunchProfile? = nil, baseURLVariable: String? = nil) -> LaunchPlan {
        LaunchPlan(profile: profile, identityConfig: identityConfig, identity: identity, baseURLVariable: baseURLVariable)
    }
}
