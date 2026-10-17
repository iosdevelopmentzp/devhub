import Foundation

package enum ConfigPaths {
    package static let folderName = ".devhub"
    package static let subfolders = ["actions", "scripts", "tabs"]

    package static func layers(projectPath: String, home: String) -> [ConfigLayerInfo] {
        let name = URL(fileURLWithPath: projectPath).lastPathComponent
        return [
            ConfigLayerInfo(layer: .global, directory: home + "/" + folderName, exists: false),
            ConfigLayerInfo(layer: .project, directory: projectPath + "/" + folderName, exists: false),
            ConfigLayerInfo(layer: .user, directory: home + "/" + folderName + "/projects/" + name, exists: false)
        ]
    }
}
