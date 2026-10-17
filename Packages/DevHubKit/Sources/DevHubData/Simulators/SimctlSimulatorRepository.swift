import Foundation
import DevHubDomain

struct SimctlSimulatorRepository: SimulatorRepository {
    let shell: ShellRunner
    let simctl: SimctlRunner

    private static let stateAlreadyReached: Set<Int32> = [149]

    init(shell: ShellRunner) {
        self.shell = shell
        simctl = SimctlRunner(shell: shell)
    }

    func list() async throws -> [SimulatorGroup] {
        let result = try await shell.run("xcrun", ["simctl", "list", "devices", "available", "-j"], cwd: nil)
        guard result.exitCode == 0 else { throw SimulatorError.command(result.stderr.trimmed) }
        return try SimctlListParser.parse(Data(result.stdout.utf8))
    }

    func boot(udid: String) async throws {
        try await simctl.run(["boot", udid], allowingExit: Self.stateAlreadyReached, failure: SimulatorError.command)
    }

    func shutdown(udid: String) async throws {
        try await simctl.run(["shutdown", udid], allowingExit: Self.stateAlreadyReached, failure: SimulatorError.command)
    }

    func erase(udid: String) async throws {
        try await shutdown(udid: udid)
        try await simctl.run(["erase", udid], failure: SimulatorError.command)
    }

    func openInSimulatorApp(udid: String) async throws {
        let result = try await shell.run("open", ["-a", "Simulator", "--args", "-CurrentDeviceUDID", udid], cwd: nil)
        guard result.exitCode == 0 else { throw SimulatorError.command(result.stderr.trimmed) }
    }

    func uninstallUserApps(udid: String, wasBooted: Bool) async throws -> [String] {
        try await whileBooted(udid: udid, wasBooted: wasBooted) {
            let apps = try await userApps(udid: udid)
            for app in apps {
                try await simctl.run(["uninstall", udid, app.bundleID], failure: SimulatorError.command)
            }
            return apps.map(\.name)
        }
    }

    func uninstall(udid: String, bundleID: String, wasBooted: Bool) async throws {
        try await whileBooted(udid: udid, wasBooted: wasBooted) {
            _ = try await simctl.run(["uninstall", udid, bundleID], failure: SimulatorError.command)
        }
    }

    func install(udid: String, appPath: String) async throws {
        try await simctl.run(["install", udid, appPath], failure: SimulatorError.command)
    }

    func uninstallQuietly(udid: String, bundleID: String) async {
        _ = try? await shell.run("xcrun", ["simctl", "uninstall", udid, bundleID], cwd: nil)
    }

    func resetKeychain(udid: String) async throws {
        try await simctl.run(["keychain", udid, "reset"], failure: SimulatorError.command)
    }

    func launch(udid: String, bundleID: String, waitForDebugger: Bool, environment: [String: String]) async throws -> Int32? {
        let arguments = ["simctl", "launch", "--terminate-running-process"] + (waitForDebugger ? ["--wait-for-debugger"] : []) + [udid, bundleID]
        let result = try await shell.run("xcrun", arguments, cwd: nil, environment: environment.childEnvironment)
        guard result.exitCode == 0 else { throw SimulatorError.command(result.failureMessage) }
        return LaunchOutput.pid(from: result.stdout)
    }

    func installedAppCounts(udids: [String]) async -> [String: Int] {
        let devices = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Developer/CoreSimulator/Devices")
        return await Task.detached {
            var counts: [String: Int] = [:]
            for udid in udids {
                let bundles = devices.appendingPathComponent("\(udid)/data/Containers/Bundle/Application")
                counts[udid] = (try? FileManager.default.contentsOfDirectory(atPath: bundles.path))?.filter { $0.hasPrefix(".") == false }.count ?? 0
            }
            return counts
        }.value
    }

    private func userApps(udid: String) async throws -> [(bundleID: String, name: String)] {
        let result = try await shell.run("xcrun", ["simctl", "listapps", udid], cwd: nil)
        guard result.exitCode == 0 else { throw SimulatorError.command(result.failureMessage) }
        guard
            let object = try? PropertyListSerialization.propertyList(from: Data(result.stdout.utf8), format: nil) as? [String: [String: Any]]
        else {
            throw SimulatorError.malformedList
        }
        return object
            .filter { $0.value["ApplicationType"] as? String == "User" }
            .map { bundleID, info in
                (bundleID, info["CFBundleDisplayName"] as? String ?? info["CFBundleName"] as? String ?? bundleID)
            }
            .sorted { $0.name < $1.name }
    }

    private func whileBooted<T>(udid: String, wasBooted: Bool, _ work: () async throws -> T) async throws -> T {
        if wasBooted == false {
            try await boot(udid: udid)
            try await simctl.run(["bootstatus", udid], failure: SimulatorError.command)
        }
        do {
            let value = try await work()
            if wasBooted == false {
                try await shutdown(udid: udid)
            }
            return value
        } catch {
            if wasBooted == false {
                try? await shutdown(udid: udid)
            }
            throw error
        }
    }
}
