import Foundation

nonisolated struct LaunchRequest: Hashable, Sendable {
    var simulatorID: String
    var bundleID: String
    var arguments: [String]
    var environment: [String: String]
    var waitsForDebugger: Bool
}

nonisolated protocol SimulatorProviding: Sendable {
    func list() async throws -> [SimulatorInfo]
    func executableName(simulatorID: String, bundleID: String) async throws -> String
    func boot(_ simulatorID: String) async throws
    func shutdown(_ simulatorID: String) async throws
    func erase(_ simulatorID: String) async throws
    func terminate(simulatorID: String, bundleID: String) async
    func uninstall(simulatorID: String, bundleID: String) async throws
    func resetKeychain(_ simulatorID: String) async throws
    func install(simulatorID: String, appPath: String) async throws
    func launch(_ request: LaunchRequest) async throws -> Int?
    func openURL(simulatorID: String, url: String) async throws
    func push(simulatorID: String, bundleID: String, payload: String) async throws
    func showInSimulatorApp(_ simulatorID: String) async throws
    func userApps(_ simulatorID: String) async throws -> [InstalledApp]
    func isInstalled(simulatorID: String, bundleID: String) async -> Bool
    func dataContainer(simulatorID: String, bundleID: String) async throws -> String
    func writeDefaults(simulatorID: String, bundleID: String, defaults: [ProfileDefault]) async throws
    func statusLine(script: String, environment: [String: String], folder: String) async throws -> String?
}

nonisolated struct MockSimulatorProvider: SimulatorProviding {
    func list() async throws -> [SimulatorInfo] {
        [
            SimulatorInfo(id: "A", name: "iPhone 17 Pro", runtime: "iOS 26.0", state: .booted, appCount: 2, isFavorite: true),
            SimulatorInfo(id: "B", name: "iPhone 17", runtime: "iOS 26.0", state: .shutdown, appCount: 0, isFavorite: false),
            SimulatorInfo(id: "C", name: "iPad Air", runtime: "iOS 26.0", state: .shutdown, appCount: 1, isFavorite: false)
        ]
    }

    func executableName(simulatorID: String, bundleID: String) async throws -> String { "SampleApp" }
    func boot(_ simulatorID: String) async throws {}
    func shutdown(_ simulatorID: String) async throws {}
    func erase(_ simulatorID: String) async throws {}
    func terminate(simulatorID: String, bundleID: String) async {}
    func uninstall(simulatorID: String, bundleID: String) async throws {}
    func resetKeychain(_ simulatorID: String) async throws {}
    func install(simulatorID: String, appPath: String) async throws {}
    func launch(_ request: LaunchRequest) async throws -> Int? { 1234 }
    func openURL(simulatorID: String, url: String) async throws {}
    func push(simulatorID: String, bundleID: String, payload: String) async throws {}
    func showInSimulatorApp(_ simulatorID: String) async throws {}
    func userApps(_ simulatorID: String) async throws -> [InstalledApp] { [] }
    func isInstalled(simulatorID: String, bundleID: String) async -> Bool { true }
    func dataContainer(simulatorID: String, bundleID: String) async throws -> String { "/tmp" }
    func writeDefaults(simulatorID: String, bundleID: String, defaults: [ProfileDefault]) async throws {}
    func statusLine(script: String, environment: [String: String], folder: String) async throws -> String? { "Environment: staging" }
}
