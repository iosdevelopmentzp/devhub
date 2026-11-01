import Foundation

package struct AppData: Hashable, Sendable {
    package var bundleID: String
    package var container: String
    package var groups: [AppDataFile]
    package var folders: [AppDataFile]
    package var databases: [AppDataFile]
    package var suites: [AppDefaultsSuite]

    package init(
        bundleID: String,
        container: String,
        groups: [AppDataFile],
        folders: [AppDataFile],
        databases: [AppDataFile],
        suites: [AppDefaultsSuite]
    ) {
        self.bundleID = bundleID
        self.container = container
        self.groups = groups
        self.folders = folders
        self.databases = databases
        self.suites = suites
    }
}
