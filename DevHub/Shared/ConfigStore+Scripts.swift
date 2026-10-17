import Foundation

extension ConfigStore {
    func resolveScript(_ path: String) -> String? {
        let manager = FileManager.default
        if path.hasPrefix("/") {
            return manager.isExecutableFile(atPath: path) ? path : nil
        }
        var folders = [ConfigLayer.user, .project, .global].compactMap { layer in
            resolved.layers.first { $0.layer == layer }?.directory
        }
        if let project = session.project?.path {
            folders.append(project)
        }
        return folders.map { $0 + "/" + path }.first { manager.isExecutableFile(atPath: $0) }
    }
}
