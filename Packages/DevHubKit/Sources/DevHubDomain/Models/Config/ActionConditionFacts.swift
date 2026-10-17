import Foundation

package struct ActionConditionFacts: Hashable, Sendable {
    package var isGitClean: Bool?
    package var isTargetBooted: Bool
    package var installedTools: Set<String>
    package var kind: ProjectKind?
    package var hostKind: CodeHostKind?

    package init(
        isGitClean: Bool?,
        isTargetBooted: Bool,
        installedTools: Set<String>,
        kind: ProjectKind?,
        hostKind: CodeHostKind?
    ) {
        self.isGitClean = isGitClean
        self.isTargetBooted = isTargetBooted
        self.installedTools = installedTools
        self.kind = kind
        self.hostKind = hostKind
    }
}
