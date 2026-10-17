import Foundation

package struct ConfigIssue: Identifiable, Hashable, Sendable {
    package var layer: ConfigLayer
    package var fileName: String
    package var message: String

    package var id: String {
        "\(layer.rawValue)/\(fileName)/\(message)"
    }

    package init(
        layer: ConfigLayer,
        fileName: String,
        message: String
    ) {
        self.layer = layer
        self.fileName = fileName
        self.message = message
    }
}
