import Foundation

package protocol SimulatorRepository: Sendable {
    func list() async throws -> [SimulatorGroup]
    func boot(udid: String) async throws
    func waitUntilBooted(udid: String) async throws
    func shutdown(udid: String) async throws
    func erase(udid: String) async throws
    func openInSimulatorApp(udid: String) async throws
    func uninstallUserApps(udid: String, wasBooted: Bool) async throws -> [String]
    func installedAppCounts(udids: [String]) async -> [String: Int]
    func uninstall(udid: String, bundleID: String, wasBooted: Bool) async throws
    func install(udid: String, appPath: String) async throws
    func uninstallQuietly(udid: String, bundleID: String) async
    func resetKeychain(udid: String) async throws
    func launch(udid: String, bundleID: String, waitForDebugger: Bool, environment: [String: String], arguments: [String]) async throws -> Int32?
    func writeDefaults(udid: String, bundleID: String, defaults: [ProfileDefault]) async throws
}
