import Foundation
import DevHubDomain

extension MockData {
    package static let identities: [Simulator.ID: AppIdentity] = [
        "sim-17pro": AppIdentity(
            isInstalled: true,
            version: "1.5.2",
            hasDebugHooks: true,
            storedEnvironment: "dev",
            lastDeviceID: "dmyv-user54",
            user: AppIdentity.User(name: "TesCalls", publicID: "246264098424"),
            apiHost: "api-dev.example.com",
            lastLaunch: ago(minutes: 12)
        )
    ]
}
