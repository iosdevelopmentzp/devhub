import Foundation

package struct GitHostConfig: Codable, Hashable, Sendable {
    package var kind: CodeHostKind? = nil
    package var name: String? = nil

    package init(kind: CodeHostKind? = nil, name: String? = nil) {
        self.kind = kind
        self.name = name
    }
}
