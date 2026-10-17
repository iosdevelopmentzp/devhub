import Foundation

package struct ConfigLayerFiles: Hashable, Sendable {
    package var layer: ConfigLayer
    package var directory: String
    package var exists: Bool
    package var projectFile: ConfigFile? = nil
    package var actionFiles: [ConfigFile] = []
    package var scriptFiles: [ScriptFile] = []
    package var tabFiles: [ConfigFile] = []
    package var readIssues: [ConfigIssue] = []

    package init(
        layer: ConfigLayer,
        directory: String,
        exists: Bool,
        projectFile: ConfigFile? = nil,
        actionFiles: [ConfigFile] = [],
        scriptFiles: [ScriptFile] = [],
        tabFiles: [ConfigFile] = [],
        readIssues: [ConfigIssue] = []
    ) {
        self.layer = layer
        self.directory = directory
        self.exists = exists
        self.projectFile = projectFile
        self.actionFiles = actionFiles
        self.scriptFiles = scriptFiles
        self.tabFiles = tabFiles
        self.readIssues = readIssues
    }
}
