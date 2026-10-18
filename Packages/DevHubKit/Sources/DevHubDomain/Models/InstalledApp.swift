import Foundation

package struct InstalledApp: Hashable, Sendable {
    package var isInstalled: Bool
    package var version: String?
    package var hasIdentityHook: Bool
    package var keepsIdentity: Bool
    package var storedProfileID: String?

    package static let notInstalled = InstalledApp(isInstalled: false, version: nil, hasIdentityHook: false, keepsIdentity: false, storedProfileID: nil)

    package init(
        isInstalled: Bool,
        version: String?,
        hasIdentityHook: Bool,
        keepsIdentity: Bool,
        storedProfileID: String?
    ) {
        self.isInstalled = isInstalled
        self.version = version
        self.hasIdentityHook = hasIdentityHook
        self.keepsIdentity = keepsIdentity
        self.storedProfileID = storedProfileID
    }
}
