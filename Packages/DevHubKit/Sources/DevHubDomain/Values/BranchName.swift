import Foundation

package struct BranchName: Hashable, Sendable {
    package static let defaultBaseRef = "origin/main"

    private static let remotePrefix = "origin/"

    package let ref: String

    package init(_ ref: String) {
        self.ref = ref
    }

    package var local: String {
        ref.hasPrefix(Self.remotePrefix) ? String(ref.dropFirst(Self.remotePrefix.count)) : ref
    }

    package var remoteRef: String {
        Self.remotePrefix + local
    }
}
