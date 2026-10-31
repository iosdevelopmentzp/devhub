import Foundation

package struct BuildRequest: Sendable {
    package var projectPath: String
    package var container: String?
    package var scheme: String
    package var configuration: String
    package var incremental: Bool
    package var simulatorUDID: String
    package var simulatorName: String
    package var cleanInstall: Bool
    package var launch: LaunchPlan
    package var attachDebugger: Bool
    package var launchesApp = true

    package init(
        projectPath: String,
        container: String?,
        scheme: String,
        configuration: String,
        incremental: Bool,
        simulatorUDID: String,
        simulatorName: String,
        cleanInstall: Bool,
        launch: LaunchPlan,
        attachDebugger: Bool,
        launchesApp: Bool = true
    ) {
        self.projectPath = projectPath
        self.container = container
        self.scheme = scheme
        self.configuration = configuration
        self.incremental = incremental
        self.simulatorUDID = simulatorUDID
        self.simulatorName = simulatorName
        self.cleanInstall = cleanInstall
        self.launch = launch
        self.attachDebugger = attachDebugger
        self.launchesApp = launchesApp
    }
}
