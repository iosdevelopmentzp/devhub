import DevHubDomain
import Foundation
import DevHubTestSupport

enum AppIdentityFixture {
    static let installed = AppIdentity(
        isInstalled: true,
        version: "4.12.0 (812)",
        hasDebugHooks: true,
        storedEnvironment: "dev",
        lastDeviceID: "devhub-3f9a1c2e",
        user: AppIdentity.User(name: "Sam Test", publicID: "u_48213"),
        apiHost: "api.dev.example.com",
        lastLaunch: Date(timeIntervalSinceNow: -300)
    )

    static let fresh = AppIdentity(isInstalled: true, version: "4.12.0 (812)", hasDebugHooks: false)

    static let config = DeviceIdentityConfig.example
}
