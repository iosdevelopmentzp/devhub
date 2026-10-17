@testable import DevHubDomain
import DevHubTestSupport

enum BuildRequestFixture {
    static let udid = "SIM-1"
    static let simulatorName = "iPhone 17"
    static let product = BuildProduct(appPath: "/derived/App.app", bundleID: "com.example.app")

    static let incremental = BuildRequest(
        projectPath: "/repo",
        container: nil,
        scheme: "App",
        configuration: "Debug",
        incremental: true,
        simulatorUDID: udid,
        simulatorName: simulatorName,
        identity: nil,
        cleanInstall: false,
        attachDebugger: false
    )

    static func identity(deviceID: String?, environment: String?) -> BuildIdentity {
        BuildIdentity(config: .example, deviceID: deviceID, environment: environment)
    }
}
