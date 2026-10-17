import Foundation

package struct IdentityLaunch: Sendable {
    package var simulator: Simulator
    package var deviceID: String?
    package var environment: String?
    package var forceCleanInstall: Bool
    package var attachDebugger: Bool
    package var projectPath: String
    package var fallbackAppPath: String?

    package init(
        simulator: Simulator,
        deviceID: String?,
        environment: String?,
        forceCleanInstall: Bool,
        attachDebugger: Bool,
        projectPath: String,
        fallbackAppPath: String?
    ) {
        self.simulator = simulator
        self.deviceID = deviceID
        self.environment = environment
        self.forceCleanInstall = forceCleanInstall
        self.attachDebugger = attachDebugger
        self.projectPath = projectPath
        self.fallbackAppPath = fallbackAppPath
    }
}
