import Foundation

package struct EffectiveProject: Hashable, Sendable {
    package var name: String
    package var kind: ProjectKind
    package var schemes: [String]
    package var scheme: String?
    package var configuration: String
    package var baseBranch: String
    package var bundleID: String?

    package init(
        name: String,
        kind: ProjectKind,
        schemes: [String],
        scheme: String?,
        configuration: String,
        baseBranch: String,
        bundleID: String?
    ) {
        self.name = name
        self.kind = kind
        self.schemes = schemes
        self.scheme = scheme
        self.configuration = configuration
        self.baseBranch = baseBranch
        self.bundleID = bundleID
    }
}
