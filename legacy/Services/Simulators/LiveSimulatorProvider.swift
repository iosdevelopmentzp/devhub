import Foundation

nonisolated struct SimulatorError: LocalizedError, Sendable {
    let message: String

    var errorDescription: String? { message }
}

nonisolated struct LiveSimulatorProvider: SimulatorProviding {
    static let alreadyInStateCode: Int32 = 149

    let shell: ShellRunner
    let devicesFolder: String

    init(shell: ShellRunner, home: String) {
        self.shell = shell
        devicesFolder = home + "/Library/Developer/CoreSimulator/Devices"
    }

    func list() async throws -> [SimulatorInfo] {
        let result = try await shell.run("xcrun", ["simctl", "list", "devices", "available", "-j"], cwd: nil)
        guard result.exitCode == 0 else {
            throw SimulatorError(message: result.failureMessage)
        }
        guard let parsed = SimulatorListParser.parse(Data(result.stdout.utf8)) else {
            throw SimulatorError(message: "Could not read the simulator list.")
        }
        let folder = devicesFolder
        return await offMain {
            parsed.filter { $0.platform == "iOS" }.map { simulator in
                SimulatorInfo(
                    id: simulator.id,
                    name: simulator.name,
                    runtime: simulator.runtimeName,
                    state: simulator.isBooted ? .booted : .shutdown,
                    appCount: Self.installedAppCount(simulatorID: simulator.id, devicesFolder: folder),
                    isFavorite: false
                )
            }
        }
    }

    func executableName(simulatorID: String, bundleID: String) async throws -> String {
        let appPath = try await simctl(["get_app_container", simulatorID, bundleID, "app"]).trimmingCharacters(in: .whitespacesAndNewlines)
        let data = await offMain { FileManager.default.contents(atPath: appPath + "/Info.plist") }
        guard let data, let name = InfoPlistParser.executableName(in: data) else {
            throw SimulatorError(message: "No executable name in the Info.plist of the installed app.")
        }
        return name
    }

    func boot(_ simulatorID: String) async throws {
        try await simctl(["boot", simulatorID], accepting: [Self.alreadyInStateCode])
        try await simctl(["bootstatus", simulatorID])
    }

    func shutdown(_ simulatorID: String) async throws {
        try await simctl(["shutdown", simulatorID], accepting: [Self.alreadyInStateCode])
    }

    func erase(_ simulatorID: String) async throws {
        try await shutdown(simulatorID)
        try await simctl(["erase", simulatorID])
    }

    func terminate(simulatorID: String, bundleID: String) async {
        _ = try? await shell.run("xcrun", ["simctl", "terminate", simulatorID, bundleID], cwd: nil)
    }

    func uninstall(simulatorID: String, bundleID: String) async throws {
        try await simctl(["uninstall", simulatorID, bundleID])
    }

    func resetKeychain(_ simulatorID: String) async throws {
        try await simctl(["keychain", simulatorID, "reset"])
    }

    func install(simulatorID: String, appPath: String) async throws {
        try await simctl(["install", simulatorID, appPath])
    }

    func launch(_ request: LaunchRequest) async throws -> Int? {
        var arguments = ["simctl", "launch", "--terminate-running-process"]
        if request.waitsForDebugger {
            arguments.append("--wait-for-debugger")
        }
        arguments += [request.simulatorID, request.bundleID] + request.arguments
        let environment = Dictionary(uniqueKeysWithValues: request.environment.map { ("SIMCTL_CHILD_" + $0.key, $0.value) })
        let result = try await shell.run("xcrun", arguments, cwd: nil, environment: environment)
        guard result.exitCode == 0 else {
            throw SimulatorError(message: result.failureMessage)
        }
        return LaunchOutput.processID(in: result.stdout)
    }

    func openURL(simulatorID: String, url: String) async throws {
        try await simctl(["openurl", simulatorID, url])
    }

    func push(simulatorID: String, bundleID: String, payload: String) async throws {
        let path = NSTemporaryDirectory() + "devhub-push-\(UUID().uuidString).apns"
        try payload.write(toFile: path, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(atPath: path) }
        try await simctl(["push", simulatorID, bundleID, path])
    }

    func showInSimulatorApp(_ simulatorID: String) async throws {
        let result = try await shell.run("open", ["-a", "Simulator", "--args", "-CurrentDeviceUDID", simulatorID], cwd: nil)
        guard result.exitCode == 0 else {
            throw SimulatorError(message: result.failureMessage)
        }
    }

    func userApps(_ simulatorID: String) async throws -> [InstalledApp] {
        let text = try await simctl(["listapps", simulatorID])
        guard let apps = InstalledAppsParser.userApps(from: text) else {
            throw SimulatorError(message: "Could not read the app list of the simulator.")
        }
        return apps
    }

    func isInstalled(simulatorID: String, bundleID: String) async -> Bool {
        guard let result = try? await shell.run("xcrun", ["simctl", "get_app_container", simulatorID, bundleID, "app"], cwd: nil) else { return false }
        return result.exitCode == 0
    }

    func dataContainer(simulatorID: String, bundleID: String) async throws -> String {
        let output = try await simctl(["get_app_container", simulatorID, bundleID, "data"])
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func writeDefaults(simulatorID: String, bundleID: String, defaults: [ProfileDefault]) async throws {
        guard defaults.isEmpty == false else { return }
        let container = try await dataContainer(simulatorID: simulatorID, bundleID: bundleID)
        let folder = container + "/Library/Preferences"
        try FileManager.default.createDirectory(atPath: folder, withIntermediateDirectories: true)
        for item in defaults {
            let flags = Self.defaultsValueArguments(item)
            try await simctl(["spawn", simulatorID, "defaults", "write", "\(folder)/\(item.suite).plist", item.key] + flags)
        }
    }

    func statusLine(script: String, environment: [String: String], folder: String) async throws -> String? {
        let output = try await StatusScriptRunner(shell: shell).run(script: script, environment: environment, folder: folder)
        return SimulatorStatusParser.parse(output)
    }

    @discardableResult
    private func simctl(_ arguments: [String], accepting accepted: [Int32] = []) async throws -> String {
        let result = try await shell.run("xcrun", ["simctl"] + arguments, cwd: nil)
        guard result.exitCode == 0 || accepted.contains(result.exitCode) else {
            throw SimulatorError(message: result.failureMessage)
        }
        return result.stdout
    }

    private static func defaultsValueArguments(_ item: ProfileDefault) -> [String] {
        switch item.type ?? "string" {
        case "bool": ["-bool", item.value == "true" || item.value == "1" ? "true" : "false"]
        case "int": ["-integer", item.value]
        default: ["-string", item.value]
        }
    }

    private static func installedAppCount(simulatorID: String, devicesFolder: String) -> Int {
        let folder = "\(devicesFolder)/\(simulatorID)/data/Containers/Bundle/Application"
        let names = (try? FileManager.default.contentsOfDirectory(atPath: folder)) ?? []
        return names.filter { $0.hasPrefix(".") == false }.count
    }
}
