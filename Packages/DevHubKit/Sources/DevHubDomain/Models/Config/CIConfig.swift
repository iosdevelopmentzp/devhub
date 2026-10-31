import Foundation

package struct CIConfig: Codable, Hashable, Sendable {
    package var kind: String? = nil
    package var project: String? = nil

    package init(kind: String? = nil, project: String? = nil) {
        self.kind = kind
        self.project = project
    }
}
