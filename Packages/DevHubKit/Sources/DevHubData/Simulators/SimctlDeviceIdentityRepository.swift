import Foundation
import DevHubDomain

struct SimctlDeviceIdentityRepository: DeviceIdentityRepository {
    let shell: ShellRunner
    let simctl: SimctlRunner
    let simulators: any SimulatorRepository

    private static let appCache = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Caches/DevHub/Apps")

    init(shell: ShellRunner, simulators: any SimulatorRepository) {
        self.shell = shell
        simctl = SimctlRunner(shell: shell)
        self.simulators = simulators
    }

    func read(udid: String, config: DeviceIdentityConfig) async -> AppIdentity {
        guard
            let appPath = await container(udid: udid, bundleID: config.bundleID, kind: "app"),
            let dataPath = await container(udid: udid, bundleID: config.bundleID, kind: "data")
        else {
            return .notInstalled
        }
        let info = PlistReader.dictionary(at: URL(fileURLWithPath: appPath).appendingPathComponent("Info.plist"))
        let preferences = PlistReader.dictionary(at: environmentPlist(dataPath: dataPath, config: config))
        return AppIdentity(
            isInstalled: true,
            version: info?["CFBundleShortVersionString"] as? String,
            hasDebugHooks: await hasDebugHooks(appPath: appPath, variable: config.deviceIDVariable, executable: info?["CFBundleExecutable"] as? String),
            keepsDeviceID: await keepsDeviceID(appPath: appPath, config: config, executable: info?["CFBundleExecutable"] as? String),
            storedEnvironment: preferences?[config.environmentKey] as? String,
            lastDeviceID: nil,
            user: nil,
            apiHost: nil,
            lastLaunch: nil
        )
    }

    func setEnvironment(_ environment: String, udid: String, config: DeviceIdentityConfig) async throws {
        guard let dataPath = await container(udid: udid, bundleID: config.bundleID, kind: "data") else {
            throw DeviceIdentityError.command("\(config.bundleID) is not installed on this simulator.")
        }
        let path = environmentPlist(dataPath: dataPath, config: config).path
        if await isBooted(udid) {
            try await simctl.run(["spawn", udid, "defaults", "write", path, config.environmentKey, "-string", environment], failure: DeviceIdentityError.command)
            return
        }
        var values = PlistReader.dictionary(at: URL(fileURLWithPath: path)) ?? [:]
        values[config.environmentKey] = environment
        let data = try PropertyListSerialization.data(fromPropertyList: values, format: .binary, options: 0)
        try FileManager.default.createDirectory(atPath: (path as NSString).deletingLastPathComponent, withIntermediateDirectories: true)
        try data.write(to: URL(fileURLWithPath: path), options: .atomic)
    }

    func cleanInstall(udid: String, config: DeviceIdentityConfig, fallbackAppPath: String?) async throws {
        try await ensureBooted(udid)
        let cached = Self.appCache.appendingPathComponent("\(udid)-\(config.bundleID).app")
        if let installed = await container(udid: udid, bundleID: config.bundleID, kind: "app") {
            try? FileManager.default.createDirectory(at: Self.appCache, withIntermediateDirectories: true)
            try? FileManager.default.removeItem(at: cached)
            let copy = try await shell.run("ditto", [installed, cached.path], cwd: nil)
            guard copy.exitCode == 0 else { throw DeviceIdentityError.command(copy.failureMessage) }
        }
        let source: String
        if FileManager.default.fileExists(atPath: cached.path) {
            source = cached.path
        } else if let fallbackAppPath, FileManager.default.fileExists(atPath: fallbackAppPath) {
            source = fallbackAppPath
        } else {
            throw DeviceIdentityError.noAppToReinstall
        }
        _ = try? await shell.run("xcrun", ["simctl", "terminate", udid, config.bundleID], cwd: nil)
        _ = try? await shell.run("xcrun", ["simctl", "uninstall", udid, config.bundleID], cwd: nil)
        try await simctl.run(["keychain", udid, "reset"], failure: DeviceIdentityError.command)
        try await simctl.run(["install", udid, source], failure: DeviceIdentityError.command)
    }

    func launch(udid: String, config: DeviceIdentityConfig, deviceID: String?, waitForDebugger: Bool, environment: [String: String], arguments: [String]) async throws -> Int32? {
        try await ensureBooted(udid)
        try? await simulators.openInSimulatorApp(udid: udid)
        var variables = environment
        if let deviceID {
            variables[config.deviceIDVariable] = deviceID
        }
        if let kept = config.keptDeviceIDVariable {
            variables[kept] = deviceID ?? ""
        }
        let result = try await shell.run(
            "xcrun",
            ["simctl", "launch", "--terminate-running-process"] + (waitForDebugger ? ["--wait-for-debugger"] : []) + [udid, config.bundleID] + config.launchArguments + arguments,
            cwd: nil,
            environment: variables.childEnvironment
        )
        guard result.exitCode == 0 else { throw DeviceIdentityError.command(result.failureMessage) }
        return LaunchOutput.pid(from: result.stdout)
    }

    // MARK: Helpers

    private func container(udid: String, bundleID: String, kind: String) async -> String? {
        if let result = try? await shell.run("xcrun", ["simctl", "get_app_container", udid, bundleID, kind], cwd: nil),
           result.exitCode == 0,
           result.stdout.trimmed.isEmpty == false {
            return result.stdout.trimmed
        }
        return ContainerLocator.find(udid: udid, bundleID: bundleID, kind: kind)
    }

    private func environmentPlist(dataPath: String, config: DeviceIdentityConfig) -> URL {
        URL(fileURLWithPath: dataPath).appendingPathComponent("Library/Preferences/\(config.environmentSuite).plist")
    }

    private func keepsDeviceID(appPath: String, config: DeviceIdentityConfig, executable: String?) async -> Bool {
        guard let variable = config.keptDeviceIDVariable else { return false }
        return await hasDebugHooks(appPath: appPath, variable: variable, executable: executable)
    }

    private func hasDebugHooks(appPath: String, variable: String, executable: String?) async -> Bool {
        let app = URL(fileURLWithPath: appPath)
        let files = (try? FileManager.default.contentsOfDirectory(atPath: appPath)) ?? []
        let candidates = files.filter { $0.hasSuffix(".debug.dylib") } + [executable].compactMap { $0 }
        for name in candidates {
            let result = try? await shell.run("grep", ["-q", "-a", "-F", variable, app.appendingPathComponent(name).path], cwd: nil)
            if result?.exitCode == 0 { return true }
        }
        return false
    }

    private func isBooted(_ udid: String) async -> Bool {
        guard let result = try? await shell.run("xcrun", ["simctl", "list", "devices", "booted"], cwd: nil) else { return false }
        return result.stdout.contains(udid)
    }

    private func ensureBooted(_ udid: String) async throws {
        guard await isBooted(udid) == false else { return }
        try await simulators.boot(udid: udid)
        try await simctl.run(["bootstatus", udid], failure: DeviceIdentityError.command)
    }
}
