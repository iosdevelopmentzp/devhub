import Foundation

package struct IdentityLaunch: Sendable {
    package var simulator: Simulator
    package var bundleID: String
    package var plan: LaunchPlan
    package var attachDebugger: Bool
    package var projectPath: String
    package var container: String?
    package var fallbackAppPath: String?

    package init(
        simulator: Simulator,
        bundleID: String,
        plan: LaunchPlan,
        attachDebugger: Bool,
        projectPath: String,
        container: String?,
        fallbackAppPath: String?
    ) {
        self.simulator = simulator
        self.bundleID = bundleID
        self.plan = plan
        self.attachDebugger = attachDebugger
        self.projectPath = projectPath
        self.container = container
        self.fallbackAppPath = fallbackAppPath
    }
}
