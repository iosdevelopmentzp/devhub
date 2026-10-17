import Foundation
import DevHubDomain

struct MockDeviceIdentityRepository: DeviceIdentityRepository {

    func read(udid: String, config: DeviceIdentityConfig) async -> AppIdentity {
        MockData.identities[udid] ?? .notInstalled
    }

    func setEnvironment(_ environment: String, udid: String, config: DeviceIdentityConfig) async throws {}

    func cleanInstall(udid: String, config: DeviceIdentityConfig, fallbackAppPath: String?) async throws {
        try await Task.sleep(for: .milliseconds(800))
    }

    func launch(udid: String, config: DeviceIdentityConfig, deviceID: String?, waitForDebugger: Bool, environment: [String: String], arguments: [String]) async throws -> Int32? {
        try await Task.sleep(for: .milliseconds(300))
        return 4242
    }
}
