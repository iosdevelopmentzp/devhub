import Foundation

package enum MockSetLocationPolicy {

    package static func location(network: NetworkConfig?, projectPath: String) -> MockSetLocation {
        let project = ProjectPath(projectPath)
        guard let folder = network?.mocksFolder?.trimmed, folder.isEmpty == false else {
            return .defaultFolder(project: project.url.lastPathComponent)
        }
        let expanded = ProjectPath(folder).expanded
        guard expanded.hasPrefix("/") == false else { return .folder(expanded) }
        return .folder(project.url.appendingPathComponent(expanded).standardizedFileURL.path)
    }
}
