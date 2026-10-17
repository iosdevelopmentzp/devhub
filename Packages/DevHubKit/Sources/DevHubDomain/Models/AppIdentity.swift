import Foundation

package struct AppIdentity: Hashable, Sendable {
    package struct User: Hashable, Sendable {
        package var name: String
        package var publicID: String

        package init(name: String, publicID: String) {
            self.name = name
            self.publicID = publicID
        }
    }

    package var isInstalled: Bool
    package var version: String?
    package var hasDebugHooks: Bool
    package var keepsDeviceID: Bool = false
    package var storedEnvironment: String?
    package var lastDeviceID: String?
    package var user: User?
    package var apiHost: String?
    package var lastLaunch: Date?

    package static let notInstalled = AppIdentity(isInstalled: false, version: nil, hasDebugHooks: false)

    package init(
        isInstalled: Bool,
        version: String?,
        hasDebugHooks: Bool,
        keepsDeviceID: Bool = false,
        storedEnvironment: String? = nil,
        lastDeviceID: String? = nil,
        user: User? = nil,
        apiHost: String? = nil,
        lastLaunch: Date? = nil
    ) {
        self.isInstalled = isInstalled
        self.version = version
        self.hasDebugHooks = hasDebugHooks
        self.keepsDeviceID = keepsDeviceID
        self.storedEnvironment = storedEnvironment
        self.lastDeviceID = lastDeviceID
        self.user = user
        self.apiHost = apiHost
        self.lastLaunch = lastLaunch
    }
}
