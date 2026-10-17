import Foundation

nonisolated extension LiveWorktreeProvider {
    func derivedData(for paths: [String]) async -> DerivedDataReport {
        let located = await locate(paths)
        async let total = size(of: located.root)
        var entries: [String: DerivedDataEntry] = [:]
        for (owner, owned) in located.matches {
            var bytes: Int64 = 0
            for folder in owned {
                bytes += await size(of: folder)
            }
            entries[owner] = DerivedDataEntry(folders: owned, bytes: bytes)
        }
        return DerivedDataReport(root: located.root, totalBytes: await total, entries: entries)
    }

    func removeDerivedData(for path: String) async throws -> Int {
        let located = await locate([path])
        let folders = located.matches[path] ?? []
        for folder in folders where folder.hasPrefix(located.root + "/") {
            let result = try await shell.run("rm", ["-rf", folder], cwd: nil)
            guard result.exitCode == 0 else {
                throw GitFailure(message: result.failureMessage)
            }
        }
        return folders.count
    }

    private func locate(_ paths: [String]) async -> (root: String, matches: [String: [String]]) {
        let root = Self.derivedDataRoot()
        let folders = await offMain { Self.workspaceFolders(root: root) }
        var matches: [String: [String]] = [:]
        for folder in folders {
            guard let owner = paths.filter({ folder.workspace == $0 || folder.workspace.hasPrefix($0 + "/") }).max(by: { $0.count < $1.count }) else { continue }
            matches[owner, default: []].append(folder.path)
        }
        return (root, matches)
    }

    private func size(of folder: String) async -> Int64 {
        guard let result = try? await shell.run("du", ["-sk", folder], cwd: nil), result.exitCode == 0 else { return 0 }
        let kilobytes = result.stdout.split(whereSeparator: { $0 == "\t" || $0 == " " }).first.flatMap { Int64($0) } ?? 0
        return kilobytes * 1024
    }

    static func derivedDataRoot() -> String {
        let custom = UserDefaults(suiteName: "com.apple.dt.Xcode")?.string(forKey: "IDECustomDerivedDataLocation")
        if let custom, custom.isEmpty == false {
            let expanded = (custom as NSString).expandingTildeInPath
            if expanded.hasPrefix("/") {
                return expanded
            }
        }
        return NSHomeDirectory() + "/Library/Developer/Xcode/DerivedData"
    }

    static func workspaceFolders(root: String) -> [(path: String, workspace: String)] {
        let names = (try? FileManager.default.contentsOfDirectory(atPath: root)) ?? []
        return names.compactMap { name in
            let folder = root + "/" + name
            guard let data = FileManager.default.contents(atPath: folder + "/info.plist"),
                  let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
                  let workspace = plist["WorkspacePath"] as? String else { return nil }
            return (folder, workspace)
        }
    }
}
