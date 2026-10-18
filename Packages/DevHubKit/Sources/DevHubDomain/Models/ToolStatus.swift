import Foundation

package struct ToolStatus: Hashable, Sendable {
    package var tool: DoctorTool
    package var path: String?
    package var version: String?

    package init(tool: DoctorTool, path: String?, version: String?) {
        self.tool = tool
        self.path = path
        self.version = version
    }

    package var isInstalled: Bool {
        path != nil
    }
}
