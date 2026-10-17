import Foundation

package struct ActionContextInputs: Hashable, Sendable {
    package var projectPath: String
    package var projectName: String
    package var checkoutPath: String
    package var branch: String
    package var effective: EffectiveProject?
    package var simulatorUDID: String
    package var simulatorName: String
    package var appPath: String
    package var configDir: String
    package var item: ActionItemContext
    package var inputs: [String: String]
    package var version: String

    package init(
        projectPath: String,
        projectName: String,
        checkoutPath: String,
        branch: String,
        effective: EffectiveProject?,
        simulatorUDID: String,
        simulatorName: String,
        appPath: String,
        configDir: String,
        item: ActionItemContext,
        inputs: [String: String],
        version: String
    ) {
        self.projectPath = projectPath
        self.projectName = projectName
        self.checkoutPath = checkoutPath
        self.branch = branch
        self.effective = effective
        self.simulatorUDID = simulatorUDID
        self.simulatorName = simulatorName
        self.appPath = appPath
        self.configDir = configDir
        self.item = item
        self.inputs = inputs
        self.version = version
    }
}
