import Foundation

package protocol DeviceRepository: Sendable {
    func list() async throws -> [Simulator]
    func install(udid: String, appPath: String) async throws
    func uninstall(udid: String, bundleID: String) async throws
    func launch(udid: String, bundleID: String, environment: [String: String], arguments: [String], startStopped: Bool) async throws -> Int32?
    func inspect(udid: String, bundleID: String, identity: LaunchIdentityConfig?, storage: ProfileStorage?, localAppPath: String?) async -> InstalledApp
    func writeDefaults(udid: String, bundleID: String, defaults: [ProfileDefault]) async throws
}
