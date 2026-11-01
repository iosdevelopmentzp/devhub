import Foundation
import DevHubDomain

struct SimctlAppDataRepository: AppDataRepository {
    static let missingDomainExit: Int32 = 1

    let shell: ShellRunner
    let simctl: SimctlRunner

    init(shell: ShellRunner) {
        self.shell = shell
        simctl = SimctlRunner(shell: shell)
    }

    func read(udid: String, bundleID: String) async throws -> AppData {
        let container = try await dataContainer(udid: udid, bundleID: bundleID)
        let listed = try await groupContainers(udid: udid, bundleID: bundleID)
        var suites = [try await suite(name: bundleID, root: container, udid: udid)]
        for group in listed {
            suites.append(try await suite(name: group.name, root: group.path, udid: udid))
        }
        let roots: [(prefix: String, path: String)] = [(prefix: "", path: container)] + listed.map { (prefix: $0.name + "/", path: $0.path) }
        let scan = await Task.detached(priority: .utility) {
            (
                folders: AppDataScanner.folders(in: container),
                groups: AppDataScanner.sized(listed),
                databases: AppDataScanner.databases(in: roots)
            )
        }.value
        return AppData(bundleID: bundleID, container: container, groups: scan.groups, folders: scan.folders, databases: scan.databases, suites: suites)
    }

    func write(_ value: AppDefaultValue, key: String, plistPath: String, udid: String) async throws {
        try await simctl.run(Self.writeArguments(value, key: key, plistPath: plistPath, udid: udid), failure: AppDataError.command)
    }

    func delete(key: String, plistPath: String, udid: String) async throws {
        try await simctl.run(["spawn", udid, "defaults", "delete", plistPath, key], failure: AppDataError.command)
    }

    func reset(_ data: AppData, udid: String, includingGroups: Bool) async throws {
        _ = try? await shell.run("xcrun", ["simctl", "terminate", udid, data.bundleID], cwd: nil)
        let suites = includingGroups ? data.suites : data.suites.filter { $0.name == data.bundleID }
        for suite in suites {
            try await simctl.run(["spawn", udid, "defaults", "delete", suite.plistPath], allowingExit: [Self.missingDomainExit], failure: AppDataError.command)
        }
        let groups = includingGroups ? data.groups.map(\.path) : []
        try await Task.detached(priority: .utility) {
            try AppDataScanner.clearContainer(data.container)
            for group in groups {
                try AppDataScanner.clearGroup(group)
            }
        }.value
    }

    static func plistPath(name: String, root: String) -> String {
        (root as NSString).appendingPathComponent("Library/Preferences/\(name).plist")
    }

    static func writeArguments(_ value: AppDefaultValue, key: String, plistPath: String, udid: String) -> [String] {
        ["spawn", udid, "defaults", "write", plistPath, key] + typed(value)
    }

    private static func typed(_ value: AppDefaultValue) -> [String] {
        switch value {
        case .string(let text): ["-string", text]
        case .integer(let number): ["-integer", "\(number)"]
        case .float(let number): ["-float", "\(number)"]
        case .bool(let flag): ["-bool", flag ? "true" : "false"]
        }
    }

    private func dataContainer(udid: String, bundleID: String) async throws -> String {
        let result = try await shell.run("xcrun", ["simctl", "get_app_container", udid, bundleID, "data"], cwd: nil)
        guard result.exitCode == 0, result.stdout.trimmed.isEmpty == false else { throw AppDataError.notInstalled(bundleID) }
        return result.stdout.trimmed
    }

    private func groupContainers(udid: String, bundleID: String) async throws -> [AppDataFile] {
        let result = try await shell.run("xcrun", ["simctl", "get_app_container", udid, bundleID, "groups"], cwd: nil)
        guard result.exitCode == 0 else { return [] }
        return AppGroupListParser.groups(from: result.stdout)
    }

    private func suite(name: String, root: String, udid: String) async throws -> AppDefaultsSuite {
        let path = Self.plistPath(name: name, root: root)
        let result = try await simctl.run(["spawn", udid, "defaults", "export", path, "-"], failure: AppDataError.command)
        guard let entries = DefaultsExportParser.entries(from: result.stdout) else {
            throw AppDataError.command("defaults export returned no property list for \(name).")
        }
        return AppDefaultsSuite(name: name, plistPath: path, entries: entries)
    }
}
