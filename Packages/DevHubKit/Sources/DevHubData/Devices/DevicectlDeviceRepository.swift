import Foundation
import DevHubDomain

struct DevicectlDeviceRepository: DeviceRepository {
    let shell: ShellRunner
    let devicectl: DevicectlRunner
    let markers: AppBundleMarkers
    let scratch: URL

    init(shell: ShellRunner, scratch: URL) {
        self.shell = shell
        devicectl = DevicectlRunner(shell: shell, outputFolder: scratch.appendingPathComponent("json", isDirectory: true))
        markers = AppBundleMarkers(shell: shell)
        self.scratch = scratch
    }

    func list() async throws -> [Simulator] {
        try DevicectlListParser.parse(try await devicectl.json(["list", "devices"], failure: DeviceError.command))
    }

    func install(udid: String, appPath: String) async throws {
        try await devicectl.run(["device", "install", "app", "--device", udid, appPath], failure: DeviceError.command)
    }

    func uninstall(udid: String, bundleID: String) async throws {
        guard try await installedVersion(udid: udid, bundleID: bundleID) != nil else { return }
        try await devicectl.run(["device", "uninstall", "app", "--device", udid, bundleID], failure: DeviceError.command)
    }

    func launch(udid: String, bundleID: String, environment: [String: String], arguments: [String]) async throws -> Int32? {
        let data = try await devicectl.json(Self.launchArguments(udid: udid, bundleID: bundleID, environment: environment, arguments: arguments), failure: DeviceError.command)
        return DevicectlLaunchParser.pid(from: data)
    }

    func inspect(udid: String, bundleID: String, identity: LaunchIdentityConfig?, storage: ProfileStorage?, localAppPath: String?) async -> InstalledApp {
        guard let version = try? await installedVersion(udid: udid, bundleID: bundleID) else { return .notInstalled }
        let local = localAppPath.flatMap { path -> (path: String, executable: String?)? in
            let info = PlistReader.dictionary(at: URL(fileURLWithPath: path).appendingPathComponent("Info.plist"))
            guard info?["CFBundleIdentifier"] as? String == bundleID else { return nil }
            return (path, info?["CFBundleExecutable"] as? String)
        }
        var hasIdentityHook = false
        var keepsIdentity = false
        if let local {
            hasIdentityHook = await markers.contains(identity?.marker, appPath: local.path, executable: local.executable)
            keepsIdentity = await markers.contains(identity?.keptVariable, appPath: local.path, executable: local.executable)
        }
        return InstalledApp(
            isInstalled: true,
            version: version,
            hasIdentityHook: hasIdentityHook,
            keepsIdentity: keepsIdentity,
            storedProfileID: await storedProfile(udid: udid, bundleID: bundleID, storage: storage)
        )
    }

    func writeDefaults(udid: String, bundleID: String, defaults: [ProfileDefault]) async throws {
        let folder = scratch.appendingPathComponent("defaults/\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        for (suite, items) in Dictionary(grouping: defaults, by: \.suite) {
            let plist = folder.appendingPathComponent("\(suite).plist")
            _ = try? await devicectl.run(Self.copyArguments(udid: udid, bundleID: bundleID, from: ProfileDefaultsPlan.preferencesPath(suite: suite), to: plist.path), failure: DeviceError.command)
            for item in items {
                let result = try await shell.run("defaults", ProfileDefaultsPlan.localWriteArguments(item, folder: folder.path), cwd: nil)
                guard result.exitCode == 0 else { throw DeviceError.command(result.failureMessage) }
            }
            try await devicectl.run(Self.copyArguments(udid: udid, bundleID: bundleID, from: plist.path, to: ProfileDefaultsPlan.preferencesPath(suite: suite), direction: "to"), failure: DeviceError.command)
        }
    }

    static func launchArguments(udid: String, bundleID: String, environment: [String: String], arguments: [String]) -> [String] {
        var result = ["device", "process", "launch", "--device", udid, "--terminate-existing"]
        if environment.isEmpty == false, let json = try? JSONSerialization.data(withJSONObject: environment, options: [.sortedKeys]) {
            result += ["--environment-variables", String(decoding: json, as: UTF8.self)]
        }
        return result + [bundleID] + arguments
    }

    static func copyArguments(udid: String, bundleID: String, from source: String, to destination: String, direction: String = "from") -> [String] {
        [
            "device", "copy", direction, "--device", udid,
            "--domain-type", "appDataContainer", "--domain-identifier", bundleID,
            "--source", source, "--destination", destination
        ]
    }

    private func installedVersion(udid: String, bundleID: String) async throws -> String? {
        let data = try await devicectl.json(["device", "info", "apps", "--device", udid, "--bundle-id", bundleID], failure: DeviceError.command)
        guard let app = DevicectlAppListParser.apps(from: data).first(where: { $0.bundleID == bundleID }) else { return nil }
        return app.version ?? ""
    }

    private func storedProfile(udid: String, bundleID: String, storage: ProfileStorage?) async -> String? {
        guard let storage else { return nil }
        let folder = scratch.appendingPathComponent("prefs/\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let plist = folder.appendingPathComponent("\(storage.suite).plist")
        guard (try? await devicectl.run(Self.copyArguments(udid: udid, bundleID: bundleID, from: ProfileDefaultsPlan.preferencesPath(suite: storage.suite), to: plist.path), failure: DeviceError.command)) != nil else { return nil }
        guard let value = PlistReader.dictionary(at: plist)?[storage.key] else { return nil }
        return "\(value)"
    }
}
