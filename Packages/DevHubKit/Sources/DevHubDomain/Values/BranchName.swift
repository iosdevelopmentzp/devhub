import Foundation

package struct BranchName: Hashable, Sendable {
    package let ref: String
    package let remote: String

    package init(_ ref: String, remote: String) {
        self.ref = ref
        self.remote = remote
    }

    package var local: String {
        let prefix = remote + "/"
        return ref.hasPrefix(prefix) ? String(ref.dropFirst(prefix.count)) : ref
    }

    package var remoteRef: String {
        "\(remote)/\(local)"
    }
}
