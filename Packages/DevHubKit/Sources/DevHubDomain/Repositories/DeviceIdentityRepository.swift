import Foundation

package protocol DeviceIdentityRepository: Sendable {
    func read(udid: String, config: DeviceIdentityConfig) async -> AppIdentity
    func setEnvironment(_ environment: String, udid: String, config: DeviceIdentityConfig) async throws
    func cleanInstall(udid: String, config: DeviceIdentityConfig, fallbackAppPath: String?) async throws
    func launch(udid: String, config: DeviceIdentityConfig, deviceID: String?, waitForDebugger: Bool, environment: [String: String], arguments: [String]) async throws -> Int32?
}
