import Foundation

package protocol AppLaunchRepository: Sendable {
    func inspect(udid: String, bundleID: String, identity: LaunchIdentityConfig?, storage: ProfileStorage?) async -> InstalledApp
    func cleanInstall(udid: String, bundleID: String, fallbackAppPath: String?) async throws
}
