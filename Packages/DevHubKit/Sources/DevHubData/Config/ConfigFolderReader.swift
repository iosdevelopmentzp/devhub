import Foundation
import DevHubDomain

enum ConfigFolderReader {
    private static let headBytes = 4096

    static func read(_ info: ConfigLayerInfo) -> ConfigLayerFiles {
        let manager = FileManager.default
        var files = ConfigLayerFiles(layer: info.layer, directory: info.directory, exists: manager.fileExists(atPath: info.directory))
        guard files.exists else { return files }
        if info.layer != .global {
            files.projectFile = readText("project.json", in: info, issues: &files.readIssues)
        }
        files.actionFiles = textFiles(in: "actions", info: info, issues: &files.readIssues)
        files.tabFiles = textFiles(in: "tabs", info: info, issues: &files.readIssues)
        files.scriptFiles = scriptFiles(info: info)
        return files
    }

    private static func entries(in folder: String) -> [String] {
        let names = (try? FileManager.default.contentsOfDirectory(atPath: folder)) ?? []
        return names.filter { $0.hasPrefix(".") == false }.sorted()
    }

    private static func readText(_ name: String, in info: ConfigLayerInfo, issues: inout [ConfigIssue]) -> ConfigFile? {
        let path = info.directory + "/" + name
        guard FileManager.default.fileExists(atPath: path) else { return nil }
        do {
            return ConfigFile(name: name, text: try String(contentsOfFile: path, encoding: .utf8))
        } catch {
            issues.append(ConfigIssue(layer: info.layer, fileName: name, message: "Cannot read the file: \(error.localizedDescription)"))
            return nil
        }
    }

    private static func textFiles(in subfolder: String, info: ConfigLayerInfo, issues: inout [ConfigIssue]) -> [ConfigFile] {
        entries(in: info.directory + "/" + subfolder)
            .filter { $0.hasSuffix(".json") }
            .compactMap { readText(subfolder + "/" + $0, in: info, issues: &issues) }
    }

    private static func scriptFiles(info: ConfigLayerInfo) -> [ScriptFile] {
        let manager = FileManager.default
        return entries(in: info.directory + "/scripts").compactMap { name in
            let path = info.directory + "/scripts/" + name
            var isDirectory: ObjCBool = false
            guard manager.fileExists(atPath: path, isDirectory: &isDirectory), isDirectory.boolValue == false else { return nil }
            let handle = FileHandle(forReadingAtPath: path)
            defer { try? handle?.close() }
            let data = (try? handle?.read(upToCount: headBytes)) ?? nil
            let head = data.map { String(decoding: $0, as: UTF8.self) } ?? ""
            return ScriptFile(name: "scripts/" + name, head: head, isExecutable: manager.isExecutableFile(atPath: path))
        }
    }
}
