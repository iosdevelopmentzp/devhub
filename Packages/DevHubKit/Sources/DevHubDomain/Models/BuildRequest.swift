import Foundation

package struct BuildRequest: Sendable {
    package var projectPath: String
    package var scheme: String
    package var configuration: String
    package var incremental: Bool
    package var simulatorUDID: String
    package var simulatorName: String
    package var identity: BuildIdentity?
    package var cleanInstall: Bool
    package var attachDebugger: Bool

    package init(
        projectPath: String,
        scheme: String,
        configuration: String,
        incremental: Bool,
        simulatorUDID: String,
        simulatorName: String,
        identity: BuildIdentity?,
        cleanInstall: Bool,
        attachDebugger: Bool
    ) {
        self.projectPath = projectPath
        self.scheme = scheme
        self.configuration = configuration
        self.incremental = incremental
        self.simulatorUDID = simulatorUDID
        self.simulatorName = simulatorName
        self.identity = identity
        self.cleanInstall = cleanInstall
        self.attachDebugger = attachDebugger
    }
}
