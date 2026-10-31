import Foundation

package struct CIToolState: Hashable, Sendable {
    package var isInstalled: Bool
    package var version: String?
    package var isLoggedIn: Bool

    package init(isInstalled: Bool, version: String?, isLoggedIn: Bool) {
        self.isInstalled = isInstalled
        self.version = version
        self.isLoggedIn = isLoggedIn
    }

    package static let missing = CIToolState(isInstalled: false, version: nil, isLoggedIn: false)
}
