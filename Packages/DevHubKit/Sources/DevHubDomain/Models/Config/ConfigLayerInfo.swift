import Foundation

package struct ConfigLayerInfo: Hashable, Sendable {
    package var layer: ConfigLayer
    package var directory: String
    package var exists: Bool

    package init(
        layer: ConfigLayer,
        directory: String,
        exists: Bool
    ) {
        self.layer = layer
        self.directory = directory
        self.exists = exists
    }
}
