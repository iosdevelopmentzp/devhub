import Foundation

package struct ToolStatus: Hashable, Sendable {
    package var tool: DoctorTool
    package var path: String?
    package var version: String?
    package var latestVersion: String? = nil

    package init(tool: DoctorTool, path: String?, version: String?, latestVersion: String? = nil) {
        self.tool = tool
        self.path = path
        self.version = version
        self.latestVersion = latestVersion
    }

    package var isInstalled: Bool {
        path != nil
    }
}
