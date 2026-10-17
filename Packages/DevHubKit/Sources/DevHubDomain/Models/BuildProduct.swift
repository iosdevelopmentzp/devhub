import Foundation

package struct BuildProduct: Sendable {
    package let appPath: String
    package let bundleID: String

    package init(appPath: String, bundleID: String) {
        self.appPath = appPath
        self.bundleID = bundleID
    }
}
