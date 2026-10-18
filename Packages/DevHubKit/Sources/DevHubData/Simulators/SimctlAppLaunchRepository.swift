import Foundation
import DevHubDomain

struct SimctlAppLaunchRepository: AppLaunchRepository {
    let shell: ShellRunner
    let simctl: SimctlRunner

    private static let appCache = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Caches/DevHub/Apps")

    init(shell: ShellRunner) {
        self.shell = shell
        simctl = SimctlRunner(shell: shell)
    }

    func inspect(udid: String, bundleID: String, identity: LaunchIdentityConfig?, storage: ProfileStorage?) async -> InstalledApp {
        guard let appPath = await container(udid: udid, bundleID: bundleID, kind: "app") else { return .notInstalled }
        let info = PlistReader.dictionary(at: URL(fileURLWithPath: appPath).appendingPathComponent("Info.plist"))
        let executable = info?["CFBundleExecutable"] as? String
        return InstalledApp(
            isInstalled: true,
            version: info?["CFBundleShortVersionString"] as? String,
            hasIdentityHook: await contains(identity?.marker, appPath: appPath, executable: executable),
            keepsIdentity: await contains(identity?.keptVariable, appPath: appPath, executable: executable),
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

    // MARK: Helpers

    private func container(udid: String, bundleID: String, kind: String) async -> String? {
        if let result = try? await shell.run("xcrun", ["simctl", "get_app_container", udid, bundleID, kind], cwd: nil),
           result.exitCode == 0,
           result.stdout.trimmed.isEmpty == false {
            return result.stdout.trimmed
        }
        return ContainerLocator.find(udid: udid, bundleID: bundleID, kind: kind)
    }

    private func storedProfile(udid: String, bundleID: String, storage: ProfileStorage?) async -> String? {
        guard let storage, let folder = await container(udid: udid, bundleID: bundleID, kind: ProfileDefaultsPlan.containerKind(suite: storage.suite)) else { return nil }
        let plist = URL(fileURLWithPath: folder).appendingPathComponent("Library/Preferences/\(storage.suite).plist")
        guard let value = PlistReader.dictionary(at: plist)?[storage.key] else { return nil }
        return "\(value)"
    }

    private func contains(_ marker: String?, appPath: String, executable: String?) async -> Bool {
        guard let marker, marker.isEmpty == false else { return false }
        let app = URL(fileURLWithPath: appPath)
        let files = (try? FileManager.default.contentsOfDirectory(atPath: appPath)) ?? []
        let candidates = files.filter { $0.hasSuffix(".debug.dylib") } + [executable].compactMap { $0 }
        for name in candidates {
            let result = try? await shell.run("grep", ["-q", "-a", "-F", marker, app.appendingPathComponent(name).path], cwd: nil)
            if result?.exitCode == 0 { return true }
        }
        return false
    }
}
