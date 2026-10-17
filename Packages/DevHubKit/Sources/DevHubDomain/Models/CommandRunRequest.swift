import Foundation

package struct CommandRunRequest: Sendable {
    package var buildCommand: String?
    package var runCommand: String?
    package var folder: String
    package var environment: [String: String]
    package var target: BuildRequest

    package init(buildCommand: String?, runCommand: String?, folder: String, environment: [String: String], target: BuildRequest) {
        self.buildCommand = buildCommand
        self.runCommand = runCommand
        self.folder = folder
        self.environment = environment
        self.target = target
    }
}
