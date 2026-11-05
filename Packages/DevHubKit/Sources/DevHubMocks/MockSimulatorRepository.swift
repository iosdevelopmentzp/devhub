import Foundation
import DevHubDomain

struct MockSimulatorRepository: SimulatorRepository {

    func list() async throws -> [SimulatorGroup] {
        MockData.simulatorGroups
    }

    func boot(udid: String) async throws {
        try await Task.sleep(for: .milliseconds(900))
    }

    func waitUntilBooted(udid: String) async throws {}

    func shutdown(udid: String) async throws {
        try await Task.sleep(for: .milliseconds(300))
    }

    func erase(udid: String) async throws {
        try await Task.sleep(for: .milliseconds(600))
    }

    func simulatorApp() async -> SimulatorApp {
        .simulator
    }

    func openInSimulatorApp(udid: String) async throws {}

    func uninstallUserApps(udid: String, wasBooted: Bool) async throws -> [String] {
        try await Task.sleep(for: .milliseconds(700))
        return ["ExampleApp"]
    }

    func uninstall(udid: String, bundleID: String, wasBooted: Bool) async throws {
        try await Task.sleep(for: .milliseconds(500))
    }

    func installedAppCounts(udids: [String]) async -> [String: Int] {
        Dictionary(uniqueKeysWithValues: udids.enumerated().map { ($1, $0 % 3) })
    }

    func install(udid: String, appPath: String) async throws {
        try await Task.sleep(for: .milliseconds(400))
    }

    func uninstallQuietly(udid: String, bundleID: String) async {}

    func resetKeychain(udid: String) async throws {}

    func writeDefaults(udid: String, bundleID: String, defaults: [ProfileDefault]) async throws {}

    func launch(udid: String, bundleID: String, waitForDebugger: Bool, environment: [String: String], arguments: [String]) async throws -> Int32? {
        try await Task.sleep(for: .milliseconds(300))
        return 4242
    }
}
