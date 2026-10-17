import Foundation

package enum ConfigMergePolicy {
    package static func resolve(_ layers: [ConfigLayerFiles]) -> ResolvedConfig {
        let ordered = layers.sorted { $0.layer.rank > $1.layer.rank }
        var issues = ordered.flatMap(\.readIssues)
        var actions: [String: ResolvedAction] = [:]
        var tabs: [TabConfig] = []
        var projectObject: [String: Any] = [:]
        for files in ordered {
            if let file = files.projectFile {
                projectObject = merge(projectFile: file, into: projectObject, layer: files.layer, issues: &issues)
            }
            for action in scriptActions(files, issues: &issues) + jsonActions(files, issues: &issues) {
                actions[action.id] = action
            }
            for tab in decodeTabs(files, issues: &issues) {
                tabs.removeAll { $0.id == tab.id }
                tabs.append(tab)
            }
        }
        let project = (try? ConfigDecoding.decode(ProjectConfig.self, from: projectObject)) ?? .empty
        let sorted = actions.values.sorted { lhs, rhs in
            if lhs.origin.layer.rank != rhs.origin.layer.rank {
                return lhs.origin.layer.rank < rhs.origin.layer.rank
            }
            return lhs.config.title.localizedCaseInsensitiveCompare(rhs.config.title) == .orderedAscending
        }
        let infos = layers.map { ConfigLayerInfo(layer: $0.layer, directory: $0.directory, exists: $0.exists) }
        return ResolvedConfig(project: project, actions: sorted, tabs: tabs, issues: issues, layers: infos)
    }

    private static func merge(projectFile file: ConfigFile, into base: [String: Any], layer: ConfigLayer, issues: inout [ConfigIssue]) -> [String: Any] {
        do {
            guard let object = try ConfigDecoding.parseJSON(file.text) as? [String: Any] else {
                throw ConfigError.invalid("The file must contain one JSON object.")
            }
            _ = try ConfigDecoding.decode(ProjectConfig.self, from: object)
            return ConfigDecoding.deepMerge(base, object)
        } catch {
            issues.append(ConfigIssue(layer: layer, fileName: file.name, message: error.localizedDescription))
            return base
        }
    }

    private static func scriptActions(_ files: ConfigLayerFiles, issues: inout [ConfigIssue]) -> [ResolvedAction] {
        files.scriptFiles.compactMap { script in
            let result = ScriptHeaderParser.parse(script.head, relativePath: script.name)
            guard result.hasHeader || script.isExecutable || ScriptHeaderParser.hasShebang(script.head) else { return nil }
            for problem in result.problems {
                issues.append(ConfigIssue(layer: files.layer, fileName: script.name, message: problem))
            }
            let origin = ActionOrigin(layer: files.layer, directory: files.directory, fileName: script.name, isHeaderScript: true, isExecutable: script.isExecutable)
            return ResolvedAction(config: result.action, origin: origin)
        }
    }

    private static func jsonActions(_ files: ConfigLayerFiles, issues: inout [ConfigIssue]) -> [ResolvedAction] {
        var found: [ResolvedAction] = []
        for file in files.actionFiles {
            do {
                let root = try ConfigDecoding.parseJSON(file.text)
                let items = (root as? [Any]) ?? [root]
                for (index, item) in items.enumerated() {
                    let label = items.count > 1 ? "\(file.name) [\(index)]" : file.name
                    do {
                        let config = try ConfigDecoding.decode(ActionConfig.self, from: item)
                        let origin = ActionOrigin(layer: files.layer, directory: files.directory, fileName: file.name, isHeaderScript: false, isExecutable: true)
                        found.append(ResolvedAction(config: config, origin: origin))
                    } catch {
                        issues.append(ConfigIssue(layer: files.layer, fileName: label, message: error.localizedDescription))
                    }
                }
            } catch {
                issues.append(ConfigIssue(layer: files.layer, fileName: file.name, message: error.localizedDescription))
            }
        }
        return found
    }

    private static func decodeTabs(_ files: ConfigLayerFiles, issues: inout [ConfigIssue]) -> [TabConfig] {
        files.tabFiles.compactMap { file in
            do {
                return try ConfigDecoding.decode(TabConfig.self, from: ConfigDecoding.parseJSON(file.text))
            } catch {
                issues.append(ConfigIssue(layer: files.layer, fileName: file.name, message: error.localizedDescription))
                return nil
            }
        }
    }
}
