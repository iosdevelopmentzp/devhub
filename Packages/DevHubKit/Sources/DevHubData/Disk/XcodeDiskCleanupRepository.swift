import Foundation
import DevHubDomain

struct XcodeDiskCleanupRepository: DiskCleanupRepository {
    let shell: ShellRunner
    let simctl: SimctlRunner
    let home: URL
    let derivedDataRoot: URL

    init(shell: ShellRunner, home: URL, derivedDataRoot: URL) {
        self.shell = shell
        simctl = SimctlRunner(shell: shell)
        self.home = home
        self.derivedDataRoot = derivedDataRoot
    }

    func items() async throws -> [DiskCleanupItem] {
        let folders = await Task.detached(priority: .utility) { [home, derivedDataRoot] in
            DiskFolderScanner.items(home: home, derivedDataRoot: derivedDataRoot)
        }.value
        let devices = try await simctl.run(["list", "devices", "unavailable", "-j"], failure: DiskCleanupError.command)
        let runtimes = try await simctl.run(["runtime", "list", "-j"], failure: DiskCleanupError.command)
        let unavailable = try SimctlUnavailableDeviceParser.item(from: Data(devices.stdout.utf8))
        return folders + (unavailable.map { [$0] } ?? []) + (try SimctlRuntimeListParser.items(from: Data(runtimes.stdout.utf8)))
    }

    func size(of item: DiskCleanupItem) async -> Int64? {
        if let size = item.size { return size }
        guard item.paths.isEmpty == false else { return nil }
        guard let result = try? await shell.run("du", Self.sizeArguments(item.paths), cwd: nil) else { return nil }
        return Self.total(fromDu: result.stdout)
    }

    func clean(_ item: DiskCleanupItem) async throws {
        switch item.kind {
        case .unavailableSimulators:
            try await simctl.run(["delete", "unavailable"], failure: DiskCleanupError.command)
        case .simulatorRuntime:
            guard let runtimeID = item.runtimeID else { return }
            try await simctl.run(["runtime", "delete", runtimeID], failure: DiskCleanupError.command)
        case .staleDerivedData, .derivedData, .archives, .deviceSupport, .swiftPMCache, .cocoaPodsCache:
            try await remove(item.paths)
        }
    }

    static func sizeArguments(_ paths: [String]) -> [String] {
        ["-sck"] + paths
    }

    static func total(fromDu output: String) -> Int64? {
        let lines = output.split(separator: "\n").filter { $0.hasSuffix("\ttotal") }
        guard let kilobytes = lines.last?.split(separator: "\t").first.flatMap({ Int64($0) }) else { return nil }
        return kilobytes * 1024
    }

    static func removeArguments(_ paths: [String]) -> [String] {
        ["-rf", "--"] + paths
    }

    private func remove(_ paths: [String]) async throws {
        let roots = DiskCleanupPolicy.roots(home: home, derivedDataRoot: derivedDataRoot)
            + DiskCleanupPolicy.roots(home: home.resolvingSymlinksInPath(), derivedDataRoot: derivedDataRoot.resolvingSymlinksInPath())
        if let refused = paths.first(where: { DiskCleanupPolicy.isRemovable($0, roots: roots) == false }) {
            throw DiskCleanupError.notAllowed(refused)
        }
        guard paths.isEmpty == false else { return }
        let result = try await shell.run("/bin/rm", Self.removeArguments(paths), cwd: nil)
        guard result.exitCode == 0 else {
            throw DiskCleanupError.command(result.stderr.trimmed.isEmpty ? "rm exited with code \(result.exitCode)." : result.stderr.trimmed)
        }
    }
}
