import Foundation

package struct SimulatorStatusRequest: Hashable, Sendable {
    package var script: String
    package var layers: [ConfigLayerInfo]
    package var projectPath: String
    package var environment: [String: String]

    package init(
        script: String,
        layers: [ConfigLayerInfo],
        projectPath: String,
        environment: [String: String]
    ) {
        self.script = script
        self.layers = layers
        self.projectPath = projectPath
        self.environment = environment
    }
}
