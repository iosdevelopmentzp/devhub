import Foundation
import DevHubDomain

struct XcodeDerivedDataRepository: DerivedDataRepository {
    let shell: ShellRunner

    var root: URL {
        let custom = CFPreferencesCopyAppValue("IDECustomDerivedDataLocation" as CFString, "com.apple.dt.Xcode" as CFString) as? String
        guard let custom, custom.isEmpty == false else {
            return URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Developer/Xcode/DerivedData")
        }
        let expanded = (custom as NSString).expandingTildeInPath
        guard expanded.hasPrefix("/") else {
            return URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent(expanded)
        }
        return URL(fileURLWithPath: expanded)
    }

    func folder(forCheckout checkout: String) -> URL? {
        let wanted = normalized(checkout)
        let folders = (try? FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil)) ?? []
        return folders.first { folder in
            guard let workspace = workspacePath(of: folder) else { return false }
            return normalized((workspace as NSString).deletingLastPathComponent) == wanted
        }
    }

    func folder(forContainer container: URL) -> URL? {
        folder(forCheckout: container.deletingLastPathComponent().path)
    }

    func size(of folder: URL) async -> Int64? {
        guard let result = try? await shell.run("du", ["-sk", folder.path], cwd: nil), result.exitCode == 0 else { return nil }
        guard let kilobytes = result.stdout.split(separator: "\t").first.flatMap({ Int64($0) }) else { return nil }
        return kilobytes * 1024
    }

    func remove(_ folder: URL) throws {
        let rootPath = normalized(root.path) + "/"
        guard normalized(folder.path).hasPrefix(rootPath) else {
            throw CocoaError(.fileWriteNoPermission, userInfo: [NSFilePathErrorKey: folder.path])
        }
        try FileManager.default.removeItem(at: folder)
    }

    private func workspacePath(of folder: URL) -> String? {
        PlistReader.dictionary(at: folder.appendingPathComponent("info.plist"))?["WorkspacePath"] as? String
    }

    private func normalized(_ path: String) -> String {
        URL(fileURLWithPath: (path as NSString).expandingTildeInPath).standardizedFileURL.path.lowercased()
    }
}
