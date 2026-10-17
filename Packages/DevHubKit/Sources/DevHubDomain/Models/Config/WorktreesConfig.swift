import Foundation

package struct WorktreesConfig: Codable, Hashable, Sendable {
    package var folder: String? = nil
    package var include: [String]? = nil
    package var bootstrap: String? = nil
    package var bootstrapMarker: String? = nil

    package init(
        folder: String? = nil,
        include: [String]? = nil,
        bootstrap: String? = nil,
        bootstrapMarker: String? = nil
    ) {
        self.folder = folder
        self.include = include
        self.bootstrap = bootstrap
        self.bootstrapMarker = bootstrapMarker
    }
}
