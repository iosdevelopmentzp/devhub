import Foundation

package struct XcodeInstallation: Identifiable, Hashable, Sendable {
    package let appPath: String
    package var version: String
    package var build: String?

    package var id: String {
        appPath
    }

    package var developerDir: String {
        DeveloperDirPolicy.developerDir(of: appPath)
    }

    package init(appPath: String, version: String, build: String?) {
        self.appPath = appPath
        self.version = version
        self.build = build
    }
}
