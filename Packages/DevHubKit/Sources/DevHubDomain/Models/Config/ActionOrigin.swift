import Foundation

package struct ActionOrigin: Hashable, Sendable {
    package var layer: ConfigLayer
    package var directory: String
    package var fileName: String
    package var isHeaderScript: Bool
    package var isExecutable: Bool

    package var scriptPath: String {
        directory + "/" + fileName
    }

    package init(
        layer: ConfigLayer,
        directory: String,
        fileName: String,
        isHeaderScript: Bool,
        isExecutable: Bool
    ) {
        self.layer = layer
        self.directory = directory
        self.fileName = fileName
        self.isHeaderScript = isHeaderScript
        self.isExecutable = isExecutable
    }
}
