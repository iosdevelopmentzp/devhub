import Synchronization
@testable import DevHubDomain

final class GatedSimulatorRepository: SimulatorRepository {
    private let recorded = Mutex<[String]>([])

    var calls: [String] {
        recorded.withLock { $0 }
    }

    func waitUntilBooted(udid: String) async throws {}

    func boot(udid: String) async throws {
        record("boot")
        while Task.isCancelled == false {
            await Task.yield()
        }
        record("boot returned")
    }

    func list() async throws -> [SimulatorGroup] {
        record("list")
        return []
    }

    func shutdown(udid: String) async throws {
        record("shutdown")
    }

    func erase(udid: String) async throws {
        record("erase")
    }

    func simulatorApp() async -> SimulatorApp {
        .simulator
    }

    func openInSimulatorApp(udid: String) async throws {
        record("openInSimulatorApp")
    }

    func uninstallUserApps(udid: String, wasBooted: Bool) async throws -> [String] {
        record("uninstallUserApps")
        return []
    }

    func installedAppCounts(udids: [String]) async -> [String: Int] {
        record("installedAppCounts")
        return [:]
    }

    func uninstall(udid: String, bundleID: String, wasBooted: Bool) async throws {
        record("uninstall")
    }

    func install(udid: String, appPath: String) async throws {
        record("install")
    }

    func uninstallQuietly(udid: String, bundleID: String) async {
        record("uninstallQuietly")
    }

    func resetKeychain(udid: String) async throws {
        record("resetKeychain")
    }

    func writeDefaults(udid: String, bundleID: String, defaults: [ProfileDefault]) async throws {
        record("writeDefaults")
    }

    func launch(udid: String, bundleID: String, waitForDebugger: Bool, environment: [String: String], arguments: [String]) async throws -> Int32? {
        record("launch")
        return nil
    }

    private func record(_ call: String) {
        recorded.withLock { $0.append(call) }
    }
}
