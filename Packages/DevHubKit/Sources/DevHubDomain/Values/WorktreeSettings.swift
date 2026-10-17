import Foundation

package struct WorktreeSettings: Hashable, Sendable {
    package var folder: String?
    package var include: [String]
    package var bootstrap: String?
    package var bootstrapMarker: String?

    package static let standard = WorktreeSettings(folder: nil, include: [], bootstrap: nil, bootstrapMarker: nil)

    package init(folder: String?, include: [String], bootstrap: String?, bootstrapMarker: String?) {
        self.folder = folder
        self.include = include
        self.bootstrap = bootstrap
        self.bootstrapMarker = bootstrapMarker
    }
}
