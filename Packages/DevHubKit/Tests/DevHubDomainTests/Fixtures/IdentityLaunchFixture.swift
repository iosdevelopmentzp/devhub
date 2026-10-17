@testable import DevHubDomain

enum IdentityLaunchFixture {
    static let udid = "SIM-1"

    static let plain = IdentityLaunch(
        simulator: SimulatorFixture.booted(udid),
        deviceID: nil,
        environment: nil,
        forceCleanInstall: false,
        attachDebugger: false,
        projectPath: "/repo",
        fallbackAppPath: "/derived/App.app"
    )
}
