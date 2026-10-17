import Foundation

nonisolated struct LiveConfigProvider: ConfigProviding {
    let home: String

    func load(projectPath: String) async -> ResolvedConfig {
        let infos = ConfigPaths.layers(projectPath: projectPath, home: home)
        return await offMain {
            ConfigMerge.resolve(infos.map(ConfigFolderReader.read))
        }
    }

    func makeWatcher(projectPath: String, onChange: @escaping @Sendable () -> Void) -> ConfigWatching? {
        let infos = ConfigPaths.layers(projectPath: projectPath, home: home)
        let paths = infos.flatMap { info in
            [info.directory] + ConfigPaths.subfolders.map { info.directory + "/" + $0 }
        }
        return ConfigWatcher(paths: paths, onChange: onChange)
    }

    func createExample(projectPath: String) throws -> String {
        let folder = projectPath + "/" + ConfigPaths.folderName
        let manager = FileManager.default
        guard manager.fileExists(atPath: folder) == false else {
            throw ConfigFailure(message: "\(folder) already exists. Nothing was changed.")
        }
        for example in ExampleConfig.all {
            let path = folder + "/" + example.path
            try manager.createDirectory(atPath: (path as NSString).deletingLastPathComponent, withIntermediateDirectories: true)
            try (example.content + "\n").write(toFile: path, atomically: true, encoding: .utf8)
            if example.isExecutable {
                try manager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: path)
            }
        }
        return folder
    }

    func folderToReveal(projectPath: String) -> String? {
        let infos = ConfigPaths.layers(projectPath: projectPath, home: home)
        let preferred = [ConfigLayer.project, .user, .global]
        for layer in preferred {
            guard let info = infos.first(where: { $0.layer == layer }) else { continue }
            if FileManager.default.fileExists(atPath: info.directory) {
                return info.directory
            }
        }
        return nil
    }
}

nonisolated enum ConfigFolderReader {
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
