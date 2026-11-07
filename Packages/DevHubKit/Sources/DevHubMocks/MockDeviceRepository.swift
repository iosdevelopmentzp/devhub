import Foundation
import DevHubDomain

struct MockDeviceRepository: DeviceRepository {

    func list() async throws -> [Simulator] {
        MockData.devices
    }

    func install(udid: String, appPath: String) async throws {
        try await Task.sleep(for: .milliseconds(900))
    }

    func uninstall(udid: String, bundleID: String) async throws {
        try await Task.sleep(for: .milliseconds(500))
    }

    func launch(udid: String, bundleID: String, environment: [String: String], arguments: [String]) async throws -> Int32? {
        try await Task.sleep(for: .milliseconds(400))
        return 2424
    }

    func inspect(udid: String, bundleID: String, identity: LaunchIdentityConfig?, storage: ProfileStorage?, localAppPath: String?) async -> InstalledApp {
        MockData.installedApps[udid] ?? .notInstalled
    }

    func writeDefaults(udid: String, bundleID: String, defaults: [ProfileDefault]) async throws {}
}
