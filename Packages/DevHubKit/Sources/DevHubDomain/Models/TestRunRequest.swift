import Foundation

package struct TestRunRequest: Hashable, Sendable {
    package var projectPath: String
    package var container: String?
    package var scheme: String
    package var configuration: String
    package var simulatorUDID: String
    package var simulatorName: String
    package var onlyTests: [String] = []

    package init(
        projectPath: String,
        container: String?,
        scheme: String,
        configuration: String,
        simulatorUDID: String,
        simulatorName: String,
        onlyTests: [String] = []
    ) {
        self.projectPath = projectPath
        self.container = container
        self.scheme = scheme
        self.configuration = configuration
        self.simulatorUDID = simulatorUDID
        self.simulatorName = simulatorName
        self.onlyTests = onlyTests
    }
}
