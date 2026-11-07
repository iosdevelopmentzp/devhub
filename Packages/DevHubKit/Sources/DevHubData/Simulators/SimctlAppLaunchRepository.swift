import Foundation
import DevHubDomain

struct SimctlAppLaunchRepository: AppLaunchRepository {
    let shell: ShellRunner
    let simctl: SimctlRunner
    let markers: AppBundleMarkers

    private static let appCache = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Caches/DevHub/Apps")

    init(shell: ShellRunner) {
        self.shell = shell
        simctl = SimctlRunner(shell: shell)
        markers = AppBundleMarkers(shell: shell)
    }

    func inspect(udid: String, bundleID: String, identity: LaunchIdentityConfig?, storage: ProfileStorage?) async -> InstalledApp {
        guard let appPath = await container(udid: udid, bundleID: bundleID, kind: "app") else { return .notInstalled }
        let info = PlistReader.dictionary(at: URL(fileURLWithPath: appPath).appendingPathComponent("Info.plist"))
        let executable = info?["CFBundleExecutable"] as? String
        return InstalledApp(
            isInstalled: true,
            version: info?["CFBundleShortVersionString"] as? String,
            hasIdentityHook: await markers.contains(identity?.marker, appPath: appPath, executable: executable),
            keepsIdentity: await markers.contains(identity?.keptVariable, appPath: appPath, executable: executable),
            storedProfileID: await storedProfile(udid: udid, bundleID: bundleID, storage: storage)
        )
    }

    func cleanInstall(udid: String, bundleID: String, fallbackAppPath: String?) async throws {
        let cached = Self.appCache.appendingPathComponent("\(udid)-\(bundleID).app")
        if let installed = await container(udid: udid, bundleID: bundleID, kind: "app") {
            try? FileManager.default.createDirectory(at: Self.appCache, withIntermediateDirectories: true)
            try? FileManager.default.removeItem(at: cached)
            let copy = try await shell.run("ditto", [installed, cached.path], cwd: nil)
            guard copy.exitCode == 0 else { throw AppLaunchError.command(copy.failureMessage) }
        }
        let source: String
        if FileManager.default.fileExists(atPath: cached.path) {
            source = cached.path
        } else if let fallbackAppPath, FileManager.default.fileExists(atPath: fallbackAppPath) {
            source = fallbackAppPath
        } else {
            throw AppLaunchError.noAppToReinstall
        }
        _ = try? await shell.run("xcrun", ["simctl", "terminate", udid, bundleID], cwd: nil)
        _ = try? await shell.run("xcrun", ["simctl", "uninstall", udid, bundleID], cwd: nil)
        try await simctl.run(["keychain", udid, "reset"], failure: AppLaunchError.command)
        try await simctl.run(["install", udid, source], failure: AppLaunchError.command)
    }

    func containers(udid: String, bundleID: String) async -> AppContainers {
        guard udid.isEmpty == false, bundleID.isEmpty == false else { return .none }
        async let app = container(udid: udid, bundleID: bundleID, kind: "app")
        async let data = container(udid: udid, bundleID: bundleID, kind: "data")
        async let shared = groups(udid: udid, bundleID: bundleID)
        return AppContainers(app: await app ?? "", data: await data ?? "", groups: await shared)
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

    private func groups(udid: String, bundleID: String) async -> [AppDataFile] {
        guard let result = try? await shell.run("xcrun", ["simctl", "get_app_container", udid, bundleID, "groups"], cwd: nil),
              result.exitCode == 0 else { return [] }
        return AppGroupListParser.groups(from: result.stdout)
    }

    private func storedProfile(udid: String, bundleID: String, storage: ProfileStorage?) async -> String? {
        guard let storage, let folder = await container(udid: udid, bundleID: bundleID, kind: ProfileDefaultsPlan.containerKind(suite: storage.suite)) else { return nil }
        let plist = URL(fileURLWithPath: folder).appendingPathComponent("Library/Preferences/\(storage.suite).plist")
        guard let value = PlistReader.dictionary(at: plist)?[storage.key] else { return nil }
        return "\(value)"
    }
}
