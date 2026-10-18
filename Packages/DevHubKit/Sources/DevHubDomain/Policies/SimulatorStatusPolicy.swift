import Foundation

package enum SimulatorStatusPolicy {
    package static func candidates(script: String, layers: [ConfigLayerInfo], projectPath: String) -> [String] {
        guard script.hasPrefix("/") == false else { return [script] }
        let layerFolders = [ConfigLayer.user, .project, .global].compactMap { layer in
            layers.first { $0.layer == layer }?.directory
        }
        return (layerFolders + [projectPath]).map { ProjectPath($0).expanded + "/" + script }
    }
}
